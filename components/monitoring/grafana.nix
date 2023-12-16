{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.visualisation.enable;
in {
  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings.analytics.reporting_enabled = false;
      settings.server = {
        domain = "grafana.ajax.casa";
        protocol = "http";
        http_port = 2342;
        http_addr =
          if config.components.caddy.enable
          then "127.0.0.1"
          else "0.0.0.0";
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

      declarativePlugins = with pkgs.grafanaPlugins; [grafana-clock-panel];
    };

    services.caddy.virtualHosts."https://grafana.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = let
        gcfg = config.services.grafana;
      in ''
        reverse_proxy ${gcfg.settings.server.protocol}://${gcfg.settings.server.http_addr}:${builtins.toString gcfg.settings.server.http_port}
        import cloudflare
      '';
    };
  };
}
