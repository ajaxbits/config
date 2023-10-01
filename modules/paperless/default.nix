{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.components.paperless;

  paperlessDataDir = config.services.paperless.dataDir;
  backupEncryptionPassword = "Baggage-Crisping-Gloating5"; # not a secret, only for cloud privacy

  backup =
    pkgs.writeShellScript "paperless-backup" ''
      set -eux
      ${paperlessDataDir}/paperless-manage document_exporter ${paperlessDataDir}}/export --zip
      mkdir -p /tmp/paperless
      mv ${paperlessDataDir}/export/*.zip /tmp/paperless/paperlessExport.zip
      ${pkgs._7zz}/bin/7zz a -tzip /tmp/paperless/paperlessExportEncrypted.zip -m0=lzma -pBaggage-Crisping-Gloating5 /tmp/paperless/paperlessExport.zip
      ${pkgs.rclone}/bin/rclone sync /tmp/paperless/paperlessExportEncrypted.zip r2:paperless-backup
      ${pkgs.rclone}/bin/rclone sync /tmp/paperless/paperlessExportEncrypted.zip paperless-s3:alex-jackson-paperless-backups
      rm -rfv /tmp/paperless
    ''
    ++ (
      if cfg.healthchecksUrl != ""
      then "\n ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${healthchecks-url}"
      else ""
    );
in {
  options.components.paperless = {
    enable = mkEnableOption "Enable Paperless component";
    backups = {
      enable = mkEnableOption "Enable backups for paperless documents";
      healthchecksUrl = mkOption {
        description = "Healthchecks endpoint for backup monitoring";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;
      user = "paperless";
      mediaDir = "/data/documents";
      consumptionDirIsPublic = true;

      address = "0.0.0.0";
      passwordFile = "${config.age.secretsDir}/paperless/admin-password";

      extraConfig = {
        PAPERLESS_TIME_ZONE = "America/Chicago";
        # TODO: Get these working
        # PAPERLESS_TIKA_ENABLED = "1";
        # PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://paperless-gotenberg:3000";
        # PAPERLESS_TIKA_ENDPOINT = "http://paperless-tika:9998";
      };
    };

    users.users = {
      paperless = {
        isSystemUser = true;
        group = "paperless";
        extraGroups = ["documentsoperators"];
      };
    };
    users.groups = {
      paperless = {};
      documentsoperators = {};
    };

    systemd.services.paperless-backup-daily = {
      script = "${backup}";
      serviceConfig = {User = services.paperless.user;};
      startAt = "daily";
    };

    age.secrets = {
      "paperless/admin-password" = {
        file = "${self}/secrets/paperless/admin-password.age";
        mode = "440";
        owner = config.users.users.paperless.name;
        group = config.users.users.paperless.group;
      };
    };
  };
}
