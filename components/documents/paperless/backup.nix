{
  config,
  lib,
  self,
  pkgs,
  ...
}: let
  inherit (lib) mkIf optionalString;

  cfg = config.components.documents.paperless;

  backupEncryptionPassword = "Baggage-Crisping-Gloating5"; # not a secret, only for cloud privacy
in {
  config = mkIf cfg.backups.enable {
    systemd.services.paperless-backup = let
      rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";
      healthchecksUrl = cfg.backups.healthchecksUrl;
      backup = pkgs.writeShellScript "paperless-backup" ''
        set -eux
        mkdir -p /tmp/paperless
        ${config.services.paperless.dataDir}/paperless-manage document_exporter /tmp/paperless \
          --zip \
          --split-manifest
        ${pkgs._7zz}/bin/7zz a -tzip /tmp/paperless/paperlessExportEncrypted.zip -m0=lzma -p${backupEncryptionPassword} /tmp/paperless/*.zip

        ${pkgs.rclone}/bin/rclone sync \
          --config ${rcloneConfigFile} \
          --verbose \
          /tmp/paperless/paperlessExportEncrypted.zip r2:paperless-backup
        ${pkgs.rclone}/bin/rclone sync \
          --config ${rcloneConfigFile} \
          --verbose \
          /tmp/paperless/paperlessExportEncrypted.zip b2-paperless-backups:paperless-backups

        rm -rfv /tmp/paperless

        ${optionalString
          (healthchecksUrl != "")
          "${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${healthchecksUrl}"}
      '';
    in {
      script = "${backup}";
      serviceConfig = {User = config.services.paperless.user;};
    };

    systemd.timers.paperless-backup = {
      description = "Run a paperless backup on a schedule";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = "daily";
        WakeSystem = true;
        Persistent = true;
      };
    };

    users.users.paperless.extraGroups = ["rcloneoperators"];
    users.groups.rcloneoperators = {};

    age.secrets = {
      "rclone/rclone.conf" = {
        file = "${self}/secrets/rclone/rclone.conf.age";
        mode = "440";
        owner = config.users.users.paperless.name;
        group = config.users.groups.rcloneoperators.name;
      };
    };
  };
}
