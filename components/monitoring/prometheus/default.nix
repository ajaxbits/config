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
          configuration.edgerouterx = import ./edgerouterx.nix;
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
