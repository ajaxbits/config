{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkIf;
  inherit (builtins) toJSON toString;

  cfg = config.components.documents.paperless;
in
{
  imports = [ ./backup.nix ];

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;
      user = "paperless";
      mediaDir = "/data/documents";
      consumptionDirIsPublic = true;

      address = if config.components.caddy.enable then "127.0.0.1" else "0.0.0.0";
      passwordFile = "${config.age.secretsDir}/paperless/admin-password";

      extraConfig = {
        PAPERLESS_TIME_ZONE = "America/Chicago";
        PAPERLESS_TIKA_ENABLED = "1";
        PAPERLESS_TIKA_ENDPOINT = "http://127.0.0.1:5551";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://127.0.0.1:5552";
        PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
        PAPERLESS_CONSUMER_ASN_BARCODE_PREFIX = "ZB";
        PAPERLESS_OCR_USER_ARGS = toJSON { invalidate_digital_signatures = true; };
      };
    };

    services.caddy.virtualHosts."https://documents.ajax.casa" = mkIf config.components.caddy.enable {
      extraConfig =
        ''
          encode gzip zstd
          reverse_proxy http://${config.services.paperless.address}:${toString config.services.paperless.port}
        ''
        + (
          if config.components.caddy.cloudflare.enable then
            ''
              import cloudflare
            ''
          else
            ''
              tls internal
            ''
        );
    };

    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.paperless-tika = {
      image = "ghcr.io/paperless-ngx/tika:2.9.0-minimal";
      ports = [ "127.0.0.1:5551:9998" ];
    };
    virtualisation.oci-containers.containers.paperless-gotenberg = {
      image = "docker.io/gotenberg/gotenberg:8.7";
      ports = [ "127.0.0.1:5552:3000" ];
      cmd = [
        "gotenberg"
        "--chromium-disable-javascript=true"
      ];
    };

    users.users = {
      paperless = {
        isSystemUser = true;
        group = "paperless";
        extraGroups = [ "documentsoperators" ];
      };
    };
    users.groups = {
      paperless = { };
      documentsoperators = { };
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
