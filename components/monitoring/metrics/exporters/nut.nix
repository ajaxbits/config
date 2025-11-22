{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (builtins) elem;

  monCfg = config.components.monitoring;
  cfg = monCfg.metrics;
in
{
  config.services = mkIf (monCfg.enable && cfg.enable && elem "nut" cfg.exporters) {
    prometheus.exporters.nut.enable = true;
    victoriametrics.prometheusConfig.scrape_configs = [
      {
        job_name = "nut-exporter-${config.networking.hostName}";
        scrape_interval = "30s";
        metrics_path = "/ups_metrics";
        static_configs =
          let
            nutConfig = config.services.prometheus.exporters.nut;
            target = "${nutConfig.listenAddress}:${builtins.toString nutConfig.port}";
          in
          [
            {
              targets = [ target ];
              labels.host = config.networking.hostName;
            }
          ];
      }
    ];
  };
}
