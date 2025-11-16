{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.components.monitoring;
  nodeExport = hostname: ip: {
    job_name = hostname;
    static_configs = [
      {
        targets = [ "${ip}:${toString config.services.prometheus.exporters.node.port}" ];
      }
    ];
  };
in
{
  imports = [
    ./edgerouterx.nix
    ./nextdns.nix
  ];

  config = lib.mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = 9001;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002;
          extraFlags = [
            "--collector.ethtool"
            "--collector.softirqs"
            "--collector.tcpstat"
          ];
        };
        nut.enable = true;
        # TODO: bring under unifi networking umbrella
        unpoller = lib.mkIf cfg.networking.enable {
          enable = true;
          controllers = [
            {
              url = "https://wifi.ajax.casa";
              pass = config.age.secrets."prometheus/unpoller-pass".path;
              user = "unifipoller@example.com";
              verify_ssl = false;

              sites = "all";
              save_ids = true;
              save_events = true;
              save_alarms = true;
              save_dpi = true;
            }
          ];
          loki = lib.mkIf config.components.monitoring.logging.enable {
            url = "http://127.0.0.1:${builtins.toString config.services.loki.configuration.server.http_listen_port}";
            inherit (config.services.loki) user;
          };
        };
      };

      scrapeConfigs =
        [
          (nodeExport "${config.networking.hostName}" "0.0.0.0")
          (nodeExport "vpod" "172.22.2.51")
        ]
        ++ lib.optional cfg.networking.enable {
          job_name = "unifipoller";
          scrape_interval = "30s";
          static_configs = [
            {
              targets = [ "127.0.0.1:9130" ];
            }
          ];
        };
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
