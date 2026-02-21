{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (builtins) elem;

  monCfg = config.components.monitoring;
  cfg = config.components.monitoring.metrics;

  motoPort = 9731;
in
{
  config = mkIf (monCfg.enable && cfg.enable && elem "moto" cfg.exporters) {
    virtualisation.oci-containers = {
      backend = "docker";
      containers.prometheus-moto-exporter = {
        image = "ghcr.io/jahkeup/prometheus-moto-exporter:main";
        ports = [ "${toString motoPort}:9731" ];
        extraOptions = [ "--network=host" ];
      };
    };

    services.victoriametrics.prometheusConfig.scrape_configs = [
      {
        job_name = "moto-exporter-${config.networking.hostName}";
        scrape_interval = "30s";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [ "localhost:${toString motoPort}" ];
            labels.type = "moto";
            labels.host = config.networking.hostName;
          }
        ];
      }
    ];
  };
}
