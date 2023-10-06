{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.visualisation.enable;
in {
  config = lib.mkIf cfg.enable {
    # services.nginx.virtualHosts.${config.services.grafana.settings.server.domain} = {
    #   locations."/" = {
    #     proxyPass = "http://0.0.0.0:${toString config.services.grafana.settings.server.http_port}";
    #     proxyWebsockets = true;
    #   };
    # };

    services.grafana = {
      enable = true;
      settings.analytics.reporting_enabled = false;
      settings.server = {
        domain = "grafana.ajax.casa";
        protocol = "http";
        http_port = 2342;
        http_addr = "127.0.0.1";
        enable_gzip = true; # recommended for perf, change if compat is bad
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

    services.caddy.virtualHosts."http://grafana.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = let
        gcfg = config.services.grafana;
      in ''
        reverse_proxy ${gcfg.settings.server.protocol}://${gcfg.settings.server.http_addr}:${builtins.toString gcfg.settings.server.http_port}
      '';
    };
  };
}
