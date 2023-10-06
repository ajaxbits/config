{
  config,
  self,
  lib,
  ...
}: let
  cfg = config.components.monitoring;
  nodeExport = hostname: {
    job_name = hostname;
    static_configs = [
      {
        targets = ["0.0.0.0:${toString config.services.prometheus.exporters.node.port}"];
      }
    ];
  };
in {
  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = 9001;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = ["systemd"];
          port = 9002;
        };
        unpoller = lib.mkIf cfg.networking.enable {
          enable = true;
          controllers = [
            {
              url = "https://172.22.0.3:8443";
              pass = config.age.secrets."prometheus/unpoller-pass".path;
              user = "unifipoller@example.com";
              verify_ssl = false;
            }
          ];
        };
        snmp = lib.mkIf cfg.networking.enable {
          enable = true;
          configuration = {
            edgerouterx = {
              walk = [
                "1.3.6.1.2.1.2.2.1.13"
                "1.3.6.1.2.1.2.2.1.14"
                "1.3.6.1.2.1.2.2.1.19"
                "1.3.6.1.2.1.2.2.1.20"
                "1.3.6.1.2.1.2.2.1.7"
                "1.3.6.1.2.1.2.2.1.8"
                "1.3.6.1.2.1.2.2.1.9"
                "1.3.6.1.2.1.25.2.3.1.5"
                "1.3.6.1.2.1.25.2.3.1.6"
                "1.3.6.1.2.1.25.3.3.1.2"
                "1.3.6.1.2.1.31.1.1.1.1"
                "1.3.6.1.2.1.31.1.1.1.10"
                "1.3.6.1.2.1.31.1.1.1.6"
              ];
              get = [
                "1.3.6.1.2.1.25.1.1.0"
                "1.3.6.1.2.1.25.1.6.0"
                "1.3.6.1.2.1.25.1.7.0"
                "1.3.6.1.2.1.25.2.2.0"
                "1.3.6.1.2.1.6.4.0"
                "1.3.6.1.2.1.6.5.0"
                "1.3.6.1.2.1.6.6.0"
                "1.3.6.1.2.1.6.8.0"
                "1.3.6.1.2.1.6.9.0"
                "1.3.6.1.4.1.2021.11.53.0"
                "1.3.6.1.4.1.2021.4.5.0"
                "1.3.6.1.4.1.2021.4.6.0"
              ];
              metrics = [
                {
                  name = "ifInDiscards";
                  oid = "1.3.6.1.2.1.2.2.1.13";
                  type = "counter";
                  help = "The number of inbound packets which were chosen to be discarded even though no errors had been detected to prevent their being deliverable to a higher-layer protocol - 1.3.6.1.2.1.2.2.1.13";
                  indexes = [
                    {
                      labelname = "ifName";
                      type = "gauge";
                    }
                  ];
                  lookups = [
                    {
                      labels = ["ifName"];
                      labelname = "ifName";
                      oid = "1.3.6.1.2.1.31.1.1.1.1";
                      type = "DisplayString";
                    }
                  ];
                }
                # ... [other metrics]
                {
                  name = "memAvailReal";
                  oid = "1.3.6.1.4.1.2021.4.6";
                  type = "gauge";
                  help = "The amount of real/physical memory currently unused or available. - 1.3.6.1.4.1.2021.4.6";
                }
              ];
              auth.community = "Darkened4-Coroner-Pungent";
            };
          };
        };
      };

      scrapeConfigs =
        [
          (nodeExport "${config.networking.hostName}")
        ]
        ++ (
          if cfg.networking.enable
          then [
            {
              job_name = "unifipoller";
              scrape_interval = "30s";
              static_configs = [
                {
                  targets = ["127.0.0.1:9130"];
                }
              ];
            }
            {
              job_name = "snmp";
              scrape_interval = "5s";
              static_configs = [{targets = ["172.22.0.1"];}];
              metrics_path = "/snmp";
              params.module = ["edgerouterx"];
              relabel_configs = [
                {
                  source_labels = ["__address__"];
                  target_label = "__param_target";
                }
                {
                  source_labels = ["__param_target"];
                  target_label = "instance";
                }
                {
                  target_label = "__address__";
                  replacement = "127.0.0.1:9116";
                }
              ];
            }
          ]
          else []
        );
    };

    age.secrets = {
      "prometheus/unpoller-pass" = {
        file = "${self}/secrets/prometheus/unpoller-pass.age";
        mode = "440";
        owner = "unpoller-exporter";
        group = "unpoller-exporter";
      };
    };
  };
}
