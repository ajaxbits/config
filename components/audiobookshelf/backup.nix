{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    concatLines
    mkIf
    optional
    getExe
    ;
  cfg = config.components.audiobookshelf;
in
{
  config = mkIf cfg.backups.enable {
    systemd.services.audiobookshelf-backup =
      let
        rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";

        curl = getExe pkgs.curl;
        rclone = getExe pkgs.rclone;

        backup = pkgs.writeShellScript "audiobookshelf-backup" (
          concatLines (
            [
              "set -eux"
              ''
                ${rclone} sync \
                  --config ${rcloneConfigFile} \
                  --verbose \
                  --checksum \
                  --ignore-existing \
                  --transfers=4 \
                  ${cfg.audiobooksDir} b2-audiobookshelf-backups:ajaxbits-audiobookshelf-backup/audiobooks
              ''
              ''
                ${rclone} sync \
                  --config ${rcloneConfigFile} \
                  --verbose \
                  --checksum \
                  --ignore-existing \
                  --transfers=4 \
                  ${cfg.libationDataDir}/LibationContext.db b2-audiobookshelf-backups:ajaxbits-audiobookshelf-backup/libation
              ''
            ]
            ++ optional cfg.backups.metadata.enable ''
              ${rclone} sync \
                --config ${rcloneConfigFile} \
                --verbose \
                --checksum \
                --ignore-existing \
                --transfers=4 \
                ${cfg.configDir}/metadata/backups b2-audiobookshelf-backups:ajaxbits-audiobookshelf-backup/backups
            ''
            ++ optional (
              cfg.backups.healthchecksUrl != ""
            ) "${curl} -fsS -m 10 --retry 5 -o /dev/null ${cfg.backups.healthchecksUrl}"
          )
        );
      in
      {
        script = "${backup}";

        # FIXME: once libation can place files in proper places with permissions, change this
        serviceConfig = {
          User = "root";
        };
      };

    systemd.timers.audiobookshelf-backup = {
      description = "Run a audiobookshelf backup on a schedule";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "weekly";
        WakeSystem = true;
        Persistent = true;
      };
    };
  };
}
