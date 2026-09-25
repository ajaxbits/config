"""Regression checks for untrusted Paperless export paths."""

import os
from pathlib import Path
import tempfile

from backup_export import copy_export


def rejects(data_dir, staging_dir):
    try:
        copy_export(data_dir, staging_dir)
    except (OSError, ValueError):
        return
    raise AssertionError("guest-controlled symlink or special file was accepted")


with tempfile.TemporaryDirectory() as temporary:
    root = Path(temporary)
    data_dir = root / "data"
    staging_dir = root / "host-cache"
    export_dir = data_dir / "export"
    export_dir.mkdir(parents=True)
    staging_dir.mkdir()
    archive = export_dir / "paperlessExportEncrypted.zip"
    archive.write_bytes(b"completed export")

    staged = Path(copy_export(data_dir, staging_dir))
    assert staged.read_bytes() == b"completed export"
    assert staged.parent == staging_dir
    staged.unlink()

    archive.unlink()
    archive.symlink_to("/etc/passwd")
    rejects(data_dir, staging_dir)

    archive.unlink()
    archive.write_bytes(b"regular again")
    moved_dir = data_dir / "real-export"
    export_dir.rename(moved_dir)
    export_dir.symlink_to("/etc", target_is_directory=True)
    rejects(data_dir, staging_dir)

    export_dir.unlink()
    moved_dir.rename(export_dir)
    archive.unlink()
    os.mkfifo(archive)
    rejects(data_dir, staging_dir)

print("PASS: regular export copied to host staging")
print("PASS: final symlink, parent symlink, and FIFO rejected")
