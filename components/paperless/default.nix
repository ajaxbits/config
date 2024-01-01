{
  config,
  lib,
  self,
  pkgsUnstable,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOption types;
  inherit (builtins) toString;

  cfg = config.components.paperless;
in {
  imports = [./backup.nix];

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
        PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
        PAPERLESS_CONSUMER_ASN_BARCODE_PREFIX = "ZB";
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
        extraGroups = ["documentsoperators"];
      };
    };
    users.groups = {
      paperless = {};
      documentsoperators = {};
    };

    age.secrets = {
      "paperless/admin-password" = {
        file = "${self}/secrets/paperless/admin-password.age";
        mode = "440";
        owner = config.users.users.paperless.name;
        inherit (config.users.users.paperless) group;
      };
    };
  };
}
