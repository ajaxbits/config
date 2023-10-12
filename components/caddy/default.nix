{
  config,
  lib,
  ...
}: let
  cfg = config.components.caddy;

  monitorConfig = lib.mkIf (cfg.enable && config.components.monitoring.enable) {
    services.caddy.globalConfig = ''
      servers {
        metrics
      }
    '';
    services.prometheus = {
      scrapeConfigs = [
        {
          job_name = "caddy";
          scrape_interval = "15s";
          static_configs = [{targets = ["localhost:2019"];}];
        }
      ];
    };
  };
in {
  options.components.caddy = {
    enable = lib.mkEnableOption "caddy";
  };

  config = lib.mkMerge [
    {services.caddy.enable = cfg.enable;}
    monitorConfig
    {
      services.caddy.virtualHosts."http://home.ajax.casa" = {
        extraConfig = ''
          @home {
            remote_ip 172.22.0.0/16
          }
          @tailscale {
            remote_ip 100.64.0.0/10
          }
          encode gzip zstd
          reverse_proxy @home http://172.22.0.3:4119
          reverse_proxy @tailscale http://100.76.177.63:4119
        '';
      };
    }
  ];
}
