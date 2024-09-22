{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib) concatLines mkIf optional;
  cfg = config.components.bookmarks;
in
{
  config = mkIf cfg.backups.enable {
    systemd.services.linkding-backup =
      let
        rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";

        backup = pkgs.writeShellScript "linkding-backup" (
          concatLines (
            [ "set -euxo pipefail" ]
            ++ optional cfg.backups.enable ''
              BACKUP_TEMP_DIR=$(mktemp -d)

              ${pkgs.docker}/bin/docker exec ${cfg.linkding.containerName} \
                  python manage.py \
                  full_backup /etc/linkding/data/backup.zip

              ${pkgs.docker}/bin/docker cp \
                  ${cfg.linkding.containerName}:/etc/linkding/data/backup.zip \
                  $BACKUP_TEMP_DIR/backup.zip

              ${pkgs.rclone}/bin/rclone sync \
                --config ${rcloneConfigFile} \
                --verbose \
                --checksum \
                --ignore-existing \
                --transfers=4 \
                $BACKUP_TEMP_DIR/backup.zip b2-linkding-backups:ajaxbits-linkding-backup/bookmarks

              ${pkgs.rclone}/bin/rclone sync \
                --config ${rcloneConfigFile} \
                --verbose \
                --checksum \
                --ignore-existing \
                --transfers=4 \
                $BACKUP_TEMP_DIR/backup.zip r2:linkding-backup

              ${pkgs.docker}/bin/docker exec ${cfg.linkding.containerName} \
                  rm /etc/linkding/data/backup.zip

              rm -rfv $BACKUP_TEMP_DIR
            ''
            ++ optional (
              cfg.backups.healthchecksUrl != ""
            ) "${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${cfg.backups.healthchecksUrl}"
          )
        );
      in
      {
        script = "${backup}";
        serviceConfig = {
          User = config.users.users.linkding.name;
        };
      };

    systemd.timers.linkding-backup = {
      description = "Run a linkding backup on a schedule";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        WakeSystem = true;
        Persistent = true;
      };
    };
  };
}
