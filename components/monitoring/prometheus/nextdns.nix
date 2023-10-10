{
  config,
  lib,
  self,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers.nextdns-exporter = {
      image = "ghcr.io/raylas/nextdns-exporter:0.5.2";
      user = builtins.toString config.users.users.nextdns-exporter.uid;
      ports = ["127.0.0.1:9948:9948"];
      environmentFiles = [config.age.secrets."prometheus/nextdns-env".path];
      environment = {
        NEXTDNS_RESULT_WINDOW = "-1m";
      };
    };

    services.prometheus.scrapeConfigs = [
      {
        job_name = "nextdns";
        scrape_interval = "1m";
        scrape_timeout = "10s";
        static_configs = [
          {
            targets = ["127.0.0.1:9948"];
          }
        ];
      }
    ];

    users.users.nextdns-exporter = {
      uid = 1337;
      isSystemUser = true;
      group = "nextdns-exporter";
    };
    users.groups.nextdns-exporter = {};
    age.secrets = {
      "prometheus/nextdns-env" = {
        file = "${self}/secrets/prometheus/nextdns-env.age";
        mode = "440";
        owner = "nextdns-exporter";
        group = "nextdns-exporter";
      };
    };
  };
}
