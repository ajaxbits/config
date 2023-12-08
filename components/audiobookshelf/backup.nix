{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) concatLines mkIf optional;
  cfg = config.components.audiobookshelf;
in {
  config = mkIf cfg.backups.enable {
    systemd.services.audiobookshelf-backup = let
      rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";

      backup = pkgs.writeShellScript "audiobookshelf-backup" (
        concatLines (["set -eux"]
          ++ optional cfg.backups.audiobooks.enable ''
            ${pkgs.rclone}/bin/rclone sync \
              --config ${rcloneConfigFile} \
              --verbose \
              --checksum \
              --ignore-existing \
              --transfers=4 \
              ${cfg.audiobooksDir} b2:ajaxbits-audiobookshelf-backup/audiobooks
          ''
          ++ optional cfg.backups.metadata.enable ''
            ${pkgs.rclone}/bin/rclone sync \
              --config ${rcloneConfigFile} \
              --verbose \
              --checksum \
              --ignore-existing \
              --transfers=4 \
              ${cfg.configDir}/audiobookshelf/metadata/backups b2:ajaxbits-audiobookshelf-backup/backups
          ''
          ++ optional (cfg.backups.healthchecksUrl != "") "${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${cfg.backups.healthchecksUrl}")
      );
    in {
      script = "${backup}";

      # FIXME: once libation can place files in proper places with permissions, change this
      serviceConfig = {User = "root";};
    };

    systemd.timers.audiobookshelf-backup = {
      description = "Run a audiobookshelf backup on a schedule";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "weekly";
        WakeSystem = true;
        Persistent = true;
      };
    };
  };
}
