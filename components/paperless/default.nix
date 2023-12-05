{
  config,
  lib,
  self,
  pkgs,
  pkgsUnstable,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (builtins) toString;

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
      package = pkgsUnstable.paperless-ngx;
      user = "paperless";
      mediaDir = "/data/documents";
      consumptionDirIsPublic = true;

      address =
        if config.components.caddy.enable
        then "127.0.0.1"
        else "0.0.0.0";
      passwordFile = "${config.age.secretsDir}/paperless/admin-password";

      extraConfig = {
        PAPERLESS_TIME_ZONE = "America/Chicago";
        PAPERLESS_TIKA_ENABLED = "1";
        PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:5551";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:5552";
      };
    };

    services.caddy.virtualHosts."https://documents.ajax.casa" = mkIf config.components.caddy.enable {
      extraConfig =
        ''
          encode gzip zstd
          reverse_proxy http://${config.services.paperless.address}:${toString config.services.paperless.port}
        ''
        + (
          if config.components.caddy.cloudflare.enable
          then ''
            import cloudflare
          ''
          else ''
            tls internal
          ''
        );
    };

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.paperless-tika = {
      image = "ghcr.io/paperless-ngx/tika:2.9.0-minimal";
      ports = ["127.0.0.1:5551:9998"];
    };
    virtualisation.oci-containers.containers.paperless-gotenberg = {
      image = "docker.io/gotenberg/gotenberg:7.10";
      ports = ["127.0.0.1:5552:3000"];
      cmd = ["gotenberg" "--chromium-disable-javascript=true"];
    };

    users.users = {
      paperless = {
        isSystemUser = true;
        group = "paperless";
        extraGroups = ["documentsoperators" "rcloneoperators"];
      };
    };
    users.groups = {
      paperless = {};
      documentsoperators = {};
      rcloneoperators = {};
    };

    systemd.services.paperless-backup-daily = mkIf cfg.backups.enable (
      let
        rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";
        backup = pkgs.writeShellScript "paperless-backup" ''
          set -eux
          mkdir -p /tmp/paperless
          ${config.services.paperless.dataDir}/paperless-manage document_exporter /tmp/paperless --zip
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
        inherit (config.users.users.paperless) group;
      };
      "rclone/rclone.conf" = mkIf cfg.backups.enable {
        file = "${self}/secrets/rclone/rclone.conf.age";
        mode = "440";
        group = config.users.groups.rcloneoperators.name;
      };
    };
  };
}
