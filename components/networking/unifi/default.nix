{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.components.networking.unifi;
in {
  config = mkIf cfg.enable {
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
  };
}
