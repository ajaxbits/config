{
  config,
  lib,
  pkgs,
  overlays,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;

  cfg = config.components.caddy;

  pkgsCaddyPatched = pkgs.extend overlays.caddy;

  monitorConfig = mkIf (cfg.enable && config.components.monitoring.enable) {
    services.caddy.globalConfig = ''
      servers {
        metrics
      }
    '';
    # TODO: make generic
    services.prometheus = {
      scrapeConfigs = [
        {
          job_name = "caddy";
          scrape_interval = "15s";
          static_configs = [ { targets = [ "localhost:2019" ]; } ];
        }
      ];
    };
  };
in
{
  options.components.caddy = {
    enable = mkEnableOption "Enable caddy webserver";
    cloudflare.enable = mkEnableOption "Enable custom caddy binary, with Cloudflare plugin installed";
  };

  config = mkMerge [
    {
      services.caddy = {
        inherit (cfg) enable;
        extraConfig = ''
          ${builtins.readFile ./Caddyfile.extra}
        '';
      };
    }
    (mkIf cfg.cloudflare.enable {
      services.caddy = {
        package = pkgsCaddyPatched.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/cloudflare@v0.2.1" ];
          hash = "sha256-p9AIi6MSWm0umUB83HPQoU8SyPkX5pMx989zAi8d/74=";
        };
        extraConfig = lib.mkBefore ''
          (cloudflare) {
            tls {
                dns cloudflare {env.CF_API_TOKEN}
                resolvers 1.1.1.1
            }
          }
        '';
      };
      systemd.services.caddy.serviceConfig.EnvironmentFile =
        "${config.age.secretsDir}/caddy/cloudflareApiToken";
      age.secrets = {
        "caddy/cloudflareApiToken" = {
          inherit (config.services.caddy) group;
          file = ../../secrets/caddy/cloudflareApiToken.age;
          mode = "440";
          owner = config.services.caddy.user;
        };
      };

      # TODO: Address in 23.11
      systemd.services.caddy.serviceConfig.AmbientCapabilities = "CAP_NET_BIND_SERVICE";
    })

    monitorConfig
  ];
}
