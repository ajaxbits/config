{
  config,
  lib,
  pkgsUnfree,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optional;
  cfg = config.components.unifi;
in {
  options.components.unifi.enable = mkEnableOption "Enable Unifi controller";

  config = mkIf cfg.enable {
    services.unifi = {
      enable = true;
      unifiPackage = pkgsUnfree.unifi;
      mongodbPackage = pkgsUnfree.mongodb;
      openFirewall = true;
    };

    services.caddy.virtualHosts."https://wifi.ajax.casa" = mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy 127.0.0.1:8443 {
          transport http {
            tls_insecure_skip_verify
          }
        }
        import cloudflare
      '';
    };

    networking.openFirewall = optional (!config.components.caddy.enable) 8443;
  };
}
