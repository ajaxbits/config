{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config.services.prometheus = lib.mkIf cfg.enable {
    exporters.smokeping = {
      enable = true;
      listenAddress = "127.0.0.1";
      hosts = [
        "1.1.1.1"
        "1.0.0.1"
        "9.9.9.9"
        "8.8.8.8"
        "45.90.28.204"
        "45.90.30.204"
      ];
    };

    scrapeConfigs = let
      exporterCfg = config.services.prometheus.exporters.smokeping;
    in [
      {
        job_name = "smokeping";
        scrape_interval = "30s";
        metrics_path = exporterCfg.telemetryPath;
        static_configs = [
          {
            targets = ["${exporterCfg.listenAddress}:${builtins.toString exporterCfg.port}"];
          }
        ];
      }
    ];

    rules = [
      ''
        groups:
        - name: Smokeping
          interval: 30s
          rules:
          - record: smokeping_probe_success:ratio1m
            expr: increase(smokeping_response_duration_seconds_count[1m]) / increase(smokeping_requests_total[1m])
          - record: smokeping_response_duration_seconds:q50
            expr: histogram_quantile(0.50, rate(smokeping_response_duration_seconds_bucket[1m]))
          - record: smokeping_response_duration_seconds:q90
            expr: histogram_quantile(0.90, rate(smokeping_response_duration_seconds_bucket[1m]))
          - record: smokeping_response_duration_seconds:q99
            expr: histogram_quantile(0.99, rate(smokeping_response_duration_seconds_bucket[1m]))
      ''
    ];
  };
}
