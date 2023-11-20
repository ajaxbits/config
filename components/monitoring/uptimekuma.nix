{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.uptime.enable;
in {
  config = lib.mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      appriseSupport = true;
      settings.HOST =
        if config.components.caddy.enable
        then "127.0.0.1"
        else "0.0.0.0";
      settings.PORT = "4000";
    };

    services.caddy.virtualHosts."https://uptime.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${config.services.uptime-kuma.settings.HOST}:${config.services.uptime-kuma.settings.PORT}
        import cloudflare
      '';
    };
  };
}
