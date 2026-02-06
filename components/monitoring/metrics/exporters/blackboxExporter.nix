{ config, lib, ... }:
let
  inherit (lib) mkIf mkOption types;

  monCfg = config.components.monitoring;
  cfg = config.components.monitoring.metrics;

  # Default targets for ISP/internet connectivity monitoring
  defaultTargets = [
    "1.1.1.1" # Cloudflare DNS
    "8.8.8.8" # Google DNS
    "9.9.9.9" # Quad9 DNS
  ];

  blackboxPort = 9115;
in
{
  options.components.monitoring.metrics.blackbox = {
    targets = mkOption {
      type = types.listOf types.str;
      default = defaultTargets;
      description = "List of hosts to probe for ISP/connectivity monitoring.";
      example = [
        "1.1.1.1"
        "8.8.8.8"
        "192.168.1.1"
      ];
    };

    scrapeInterval = mkOption {
      type = types.str;
      default = "15s";
      description = "How often to probe targets.";
    };
  };

  config = mkIf (monCfg.enable && cfg.enable) {
    services.prometheus.exporters.blackbox = {
      enable = true;
      port = blackboxPort;
      configFile = (
        builtins.toFile "blackbox.yml" ''
          modules:
            icmp:
              prober: icmp
              timeout: 5s
              icmp:
                preferred_ip_protocol: ip4
                dont_fragment: true
            icmp_ttl:
              prober: icmp
              timeout: 5s
              icmp:
                preferred_ip_protocol: ip4
                ttl: 64
        ''
      );
    };

    services.victoriametrics.prometheusConfig.scrape_configs = [
      {
        job_name = "blackbox-icmp-${config.networking.hostName}";
        scrape_interval = cfg.blackbox.scrapeInterval;
        metrics_path = "/probe";
        params.module = [ "icmp" ];
        static_configs = [
          {
            inherit (cfg.blackbox) targets;
            labels.type = "isp";
            labels.host = config.networking.hostName;
          }
        ];
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "localhost:${toString blackboxPort}";
          }
        ];
      }
    ];
  };
}
