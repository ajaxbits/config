{
  config,
  lib,
  ...
}:
let
  cfg = config.components.podcasts.vpod;
in
{
  config = lib.mkIf cfg.enable {
    components = {
      caddy = {
        enable = true;
        cloudflare.enable = true;
      };
      cloudflared.enable = true;
    };

    services = {
      # TODO: factor
      cloudflared.tunnels."a5466e3c-1170-4a2a-ae62-1a992509f36f".ingress.${cfg.domain} = {
        service = "https://localhost:443";
        originRequest = {
          originServerName = cfg.domain;
          httpHostHeader = cfg.domain;
        };
      };
      caddy.virtualHosts."https://${cfg.domain}" = {
        extraConfig = ''
          import cloudflare
          encode gzip zstd

          reverse_proxy ${cfg.vm.ip}:${builtins.toString cfg.port}
        '';
      };
    };
  };
}
