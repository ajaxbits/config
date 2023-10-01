{
  config,
  lib,
  self,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.paperless;

  backupEncryptionPassword = "Baggage-Crisping-Gloating5"; # not a secret, only for cloud privacy
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
        PAPERLESS_TIKA_ENABLED = "1";
        PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:5551";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:5552";
      };
    };

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.paperless-tika = {
      image = "ghcr.io/paperless-ngx/tika:2.9.0-minimal";
      ports = ["127.0.0.1:5551:9998"];
    };
    virtualisation.oci-containers.containers.paperless-gotenberg = {
      image = "docker.io/gotenberg/gotenberg:7.9";
      ports = ["127.0.0.1:5552:3000"];
      cmd = ["gotenberg" "--chromium-disable-javascript=true"];
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

    systemd.services.paperless-backup-daily = mkIf cfg.backups.enable (
      let
        paperlessDataDir = config.services.paperless.dataDir;
        backup = pkgs.writeShellScript "paperless-backup" ''
          set -eux
          ${paperlessDataDir}/paperless-manage document_exporter ${paperlessDataDir}/export --zip
          mkdir -p /tmp/paperless
          mv ${paperlessDataDir}/export/*.zip /tmp/paperless/paperlessExport.zip
          ${pkgs._7zz}/bin/7zz a -tzip /tmp/paperless/paperlessExportEncrypted.zip -m0=lzma -p${backupEncryptionPassword} /tmp/paperless/paperlessExport.zip
          ${pkgs.rclone}/bin/rclone sync /tmp/paperless/paperlessExportEncrypted.zip r2:paperless-backup
          ${pkgs.rclone}/bin/rclone sync /tmp/paperless/paperlessExportEncrypted.zip paperless-s3:alex-jackson-paperless-backups
          rm -rfv /tmp/paperless
          ${(
            if cfg.backups.healthchecksUrl != ""
            then "${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${cfg.backups.healthchecksUrl}"
            else ""
          )}
        '';
      in {
        script = "${backup}";
        serviceConfig = {User = config.services.paperless.user;};
        startAt = "daily";
      }
    );

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
