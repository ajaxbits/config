{
  config,
  dataPaths,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOverride;
  cfg = config.components.documents.stirlingPdf;

  version = "1.3.2";
  configDir = "${dataPaths.containers}/stirling-pdf";
  internalPort = 8124;
  internalAddress =
    if config.components.caddy.enable then
      "127.0.0.1:${toString internalPort}"
    else
      "0.0.0.0:${toString internalPort}";
in
{
  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    systemd.tmpfiles.rules = [
      # Ensure a directory exists for the compose file
      "d ${configDir} 0755 root root -"
      # Copy the file once: only if the target does NOT exist yet
      "C ${configDir}/docker-compose.yml 0644 root root - ${./docker-compose.yml}"
    ];

    services.caddy.virtualHosts."https://pdf.ajax.casa" = mkIf config.components.caddy.enable {
      extraConfig =
        ''
          encode gzip zstd
          reverse_proxy http://${internalAddress}
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
  };
}
