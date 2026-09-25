"""Copy the guest export into host-only staging without following guest symlinks."""

import os
import shutil
import stat
import sys
import tempfile


def copy_export(data_dir, staging_dir):
    directory_flags = os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW
    data_fd = os.open(data_dir, directory_flags)
    try:
        export_fd = os.open("export", directory_flags, dir_fd=data_fd)
        try:
            source_fd = os.open(
                "paperlessExportEncrypted.zip",
                os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK,
                dir_fd=export_fd,
            )
            try:
                if not stat.S_ISREG(os.fstat(source_fd).st_mode):
                    raise ValueError("Paperless export is not a regular file")
                target_fd, target_path = tempfile.mkstemp(
                    prefix="paperless-export-",
                    suffix=".zip",
                    dir=staging_dir,
                )
                try:
                    with os.fdopen(source_fd, "rb") as source:
                        source_fd = -1
                        with os.fdopen(target_fd, "wb") as target:
                            target_fd = -1
                            shutil.copyfileobj(source, target)
                            target.flush()
                            os.fsync(target.fileno())
                except BaseException:
                    if source_fd >= 0:
                        os.close(source_fd)
                    if target_fd >= 0:
                        os.close(target_fd)
                    os.unlink(target_path)
                    raise
                return target_path
            finally:
                if source_fd >= 0:
                    os.close(source_fd)
        finally:
            os.close(export_fd)
    finally:
        os.close(data_fd)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        raise SystemExit("usage: backup_export.py DATA_DIR STAGING_DIR")
    print(copy_export(sys.argv[1], sys.argv[2]))
