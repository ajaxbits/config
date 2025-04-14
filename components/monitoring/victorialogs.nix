{ config, lib, ... }:
let
  inherit (lib) mkIf;

  monCfg = config.components.monitoring;
  cfg.enable = monCfg.enable && monCfg.victorialogs.enable;
in
{
  config = mkIf cfg.enable {
    services.victorialogs = {
      enable = true;
    };

    services.caddy.virtualHosts."https://victorialogs.ajax.casa" = mkIf config.components.caddy.enable {
      extraConfig = ''
        reverse_proxy ${config.services.victorialogs.listenAddress}
        import cloudflare
      '';
    };
  };
}
