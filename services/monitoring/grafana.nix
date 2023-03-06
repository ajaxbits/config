{config, ...}: {
  services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
    locations."/" = {
      proxyPass = "http://0.0.0.0:${toString config.services.grafana.settings.server.http_port}";
      proxyWebsockets = true;
    };
  };

  services.grafana = {
    enable = true;
    settings.analytics.reporting_enabled = false;
    settings.server = {
      domain = "grafana.agamemnon";
      protocol = "http";
      http_port = 2342;
      http_addr = "0.0.0.0";
    };
    provision = {
      enable = true;
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.prometheus.port}";
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
        }
      ];
    };
  };
}
