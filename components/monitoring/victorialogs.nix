{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.strings) hasPrefix;

  monCfg = config.components.monitoring;
  cfg.enable = monCfg.enable && monCfg.victorialogs.enable;
in
{
  config = mkIf cfg.enable {
    services = {
      victorialogs.enable = true;

      journald.upload = {
        enable = true;
        settings.Upload.URL =
          let
            ensureHost =
              listenAddress: if hasPrefix ":" listenAddress then "localhost${listenAddress}" else listenAddress;
          in
          "http://${ensureHost config.services.victorialogs.listenAddress}/insert/journald";
      };

      caddy.virtualHosts."https://victorialogs.ajax.casa" = mkIf config.components.caddy.enable {
        extraConfig = ''
          reverse_proxy ${config.services.victorialogs.listenAddress}
          import cloudflare
        '';
      };
    };
  };
}
