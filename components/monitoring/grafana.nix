{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  cfg.enable =
    config.components.monitoring.enable && config.components.monitoring.visualisation.enable;

  domain = "grafana.ajax.casa";
in
{
  config = lib.mkIf cfg.enable {
    age.secrets."grafana/secret-key" = {
      file = "${self}/secrets/grafana/secret-key.age";
      mode = "440";
      owner = "grafana";
      group = "grafana";
    };

    services.grafana = {
      declarativePlugins = with pkgs.grafanaPlugins; [
        grafana-clock-panel
      ];

      enable = true;
      settings = {
        analytics.reporting_enabled = false;
        security.secret_key = "$__file{${config.age.secrets."grafana/secret-key".path}}";
        server = {
          inherit domain;
          protocol = "http";
          http_port = 2342;
          http_addr = if config.components.caddy.enable then "127.0.0.1" else "0.0.0.0";
          enable_gzip = true; # recommended for perf, change if compat is bad
        };
      };
    };

    services.caddy.virtualHosts."https://${domain}" = lib.mkIf config.components.caddy.enable {
      extraConfig =
        let
          gcfg = config.services.grafana;
        in
        ''
          reverse_proxy ${gcfg.settings.server.protocol}://${gcfg.settings.server.http_addr}:${builtins.toString gcfg.settings.server.http_port}
          import cloudflare
        '';
    };
  };
}
