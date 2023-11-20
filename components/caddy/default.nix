{
  config,
  lib,
  pkgs,
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
    {
      services.caddy = {
        enable = cfg.enable;
        package = pkgs.caddy-patched;
      };
      systemd.services.caddy.path = [pkgs.nss];
    }
    monitorConfig
  ];
}
