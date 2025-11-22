{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkMerge;
  inherit (lib.strings) hasPrefix;

  monCfg = config.components.monitoring;
  cfg.enable = monCfg.enable && monCfg.logs.enable;

  ensureHost =
    listenAddress: if hasPrefix ":" listenAddress then "0.0.0.0${listenAddress}" else listenAddress;

  internalUrl = "${ensureHost config.services.victorialogs.listenAddress}";
  externalUrl = "https://logs.ajax.casa";
in
{
  config = mkIf cfg.enable (mkMerge [
    {
      services = {
        victorialogs.enable = true;

        journald.upload = {
          enable = true;
          settings.Upload.URL = "http://${ensureHost config.services.victorialogs.listenAddress}/insert/journald";
        };
      };
    }
    {
      services = mkIf monCfg.visualisation.enable {
        grafana = {
          declarativePlugins = with pkgs.grafanaPlugins; [
            victoriametrics-logs-datasource
          ];
          provision.datasources.settings.datasources = [
            {
              name = "VictoriaLogs";
              type = "victoriametrics-logs-datasource";
              access = "proxy";
              url = "http://${internalUrl}";
            }
          ];
        };
      };
    }
    {
      services = mkIf config.components.caddy.enable {
        caddy.virtualHosts.${externalUrl}.extraConfig = ''
          reverse_proxy ${internalUrl}
          import cloudflare
        '';
      };
    }
  ]);
}
