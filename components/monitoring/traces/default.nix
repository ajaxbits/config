{ config, lib, ... }:
let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    ;
  inherit (lib.strings) hasPrefix;

  monCfg = config.components.monitoring;
  cfg = monCfg.traces;

  ensureHost = addr: if hasPrefix ":" addr then "0.0.0.0${addr}" else addr;
  internalUrl = "http://${ensureHost config.services.victoriatraces.listenAddress}";
  externalUrl = "https://traces.ajax.casa";
in
{
  options.components.monitoring.traces.enable = mkOption {
    type = types.bool;
    default = true;
    description = "Enable tracing framework.";
  };

  config = mkIf (cfg.enable && monCfg.enable) (mkMerge [
    {
      services.victoriatraces.enable = true;

      services.caddy.virtualHosts.${externalUrl} = mkIf config.components.caddy.enable {
        extraConfig = ''
          reverse_proxy ${config.services.victoriatraces.listenAddress}
          import cloudflare
        '';
      };
    }

    (mkIf monCfg.visualisation.enable {
      # VictoriaTraces exposes a Jaeger-compatible query API.
      services.grafana.provision.datasources.settings.datasources = [
        {
          name = "VictoriaTraces";
          type = "jaeger";
          access = "proxy";
          url = "${internalUrl}/select/jaeger";
        }
      ];
    })
  ]);
}
