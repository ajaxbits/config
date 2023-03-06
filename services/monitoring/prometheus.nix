{
  config,
  unpollerPass,
  ...
}: let
  nodeExport = hostname: {
    job_name = hostname;
    static_configs = [
      {
        targets = ["0.0.0.0:${toString config.services.prometheus.exporters.node.port}"];
      }
    ];
  };
in {
  services.prometheus = {
    enable = true;
    port = 9001;
    exporters = {
      node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9002;
      };
      unpoller = {
        enable = true;
        controllers = [
          {
            url = "https://172.22.0.3:8443";
            pass = unpollerPass;
            user = "unifipoller@example.com";
            verify_ssl = false;
          }
        ];
      };
    };

    scrapeConfigs = [
      (nodeExport "${config.networking.hostName}")
      {
        job_name = "unifipoller";
        scrape_interval = "30s";
        static_configs = [
          {
            targets = ["127.0.0.1:9130"];
          }
        ];
      }
    ];
  };
}
