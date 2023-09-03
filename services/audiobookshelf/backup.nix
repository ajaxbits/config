{
  pkgs,
  audiobookshelfDir,
  healthchecks-url,
  ...
}: let
  backup = pkgs.writeShellScript "audiobookshelf-backup" ''
    set -eux
    ${pkgs.rclone}/bin/rclone sync ${audiobookshelfDir}/audiobooks b2:ajaxbits-audiobookshelf-backup/audiobooks --checksum --ignore-existing --transfers=4 --log-level=INFO
    ${pkgs.rclone}/bin/rclone sync ${audiobookshelfDir}/metadata/backups b2:ajaxbits-audiobookshelf-backup/backups --checksum --ignore-existing --transfers=4 --log-level=INFO
    ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${healthchecks-url}
  '';
in {
  systemd.services.audiobookshelf-backup-daily = {
    script = "${backup}";
    serviceConfig = {User = "root";};
  };
}
