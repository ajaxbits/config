{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;
  inherit (lib.strings) hasPrefix;

  monCfg = config.components.monitoring;
  cfg = monCfg.metrics;

  ensureHost =
    listenAddress: if hasPrefix ":" listenAddress then "0.0.0.0${listenAddress}" else listenAddress;

  internalUrl = "${ensureHost config.services.victoriametrics.listenAddress}";
  externalUrl = "https://metrics.ajax.casa";
in
{
  imports = [ ./exporters ];

  options.components.monitoring.metrics = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable metrics framework.";
    };
    exporters = mkOption {
      type = types.listOf types.str;
      default = [
        "nodeExporter"
        "nut"
      ];
      description = "List of exporters to enable.";
    };
  };

  config = mkIf (cfg.enable && monCfg.enable) (
    lib.mkMerge [
      {
        services.victoriametrics = {
          enable = true;
        };

        services.caddy.virtualHosts.${externalUrl} = mkIf config.components.caddy.enable {
          extraConfig = ''
            reverse_proxy ${config.services.victoriametrics.listenAddress}
            import cloudflare
          '';
        };
      }
      {
        services = mkIf monCfg.visualisation.enable {
          grafana = {
            declarativePlugins = with pkgs.grafanaPlugins; [
              victoriametrics-metrics-datasource
            ];
            provision.datasources.settings.datasources = [
              {
                name = "VictoriaMetrics";
                type = "victoriametrics-metrics-datasource";
                access = "proxy";
                url = internalUrl;
              }
              {
                name = "Prometheus (VictoriaMetrics)";
                type = "prometheus";
                access = "proxy";
                url = internalUrl;
              }
            ];
          };
        };
      }
    ]
  );
}
