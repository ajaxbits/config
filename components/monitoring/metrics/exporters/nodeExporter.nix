{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (builtins) elem;

  monCfg = config.components.monitoring;
  cfg = config.components.monitoring.metrics;
in
{
  config = mkIf (monCfg.enable && cfg.enable && elem "nodeExporter" cfg.exporters) {
    services = {
      prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [
          "ethtool"
          "interrupts"
          "processes"
          "softirqs"
          "systemd"
          "tcpstat"
        ];
        port = 9002;
      };

      victoriametrics.prometheusConfig.scrape_configs = [
        {
          job_name = "node-exporter-${config.networking.hostName}";
          scrape_interval = "30s";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "localhost:9002" ];
              labels.type = "node";
              labels.host = config.networking.hostName;
            }
          ];
        }
      ];
    };

  };
}
