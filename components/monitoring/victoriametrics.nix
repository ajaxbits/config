{ config, lib, ... }:
let
  inherit (lib) mkIf;

  monCfg = config.components.monitoring;
  cfg.enable = monCfg.enable && monCfg.victoriametrics.enable;
in
{
  config = mkIf cfg.enable {
    services.victoriametrics = {
      enable = true;
      prometheusConfig = {
        scrape_configs =
          let
            inherit (config.networking) hostName;
          in
          [
            {
              job_name = "node-exporter-${hostName}";
              scrape_interval = "30s";
              metrics_path = "/metrics";
              static_configs = [
                {
                  targets = [ "localhost:9002" ];
                  labels.type = "node";
                  labels.host = hostName;
                }
              ];
            }

          ];
      };
    };

    services.caddy.virtualHosts."https://victoriametrics.ajax.casa" =
      mkIf config.components.caddy.enable
        {
          extraConfig = ''
            reverse_proxy ${config.services.victoriametrics.listenAddress}
            import cloudflare
          '';
        };
  };
}
