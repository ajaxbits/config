{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.disk.enable;
in {
  config = lib.mkIf cfg.enable {
    services.scrutiny = {
      enable = true;
      host = "localhost";
      port = 9997;
    };

    services.caddy.virtualHosts."https://disks.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${config.services.scrutiny.host}:${config.services.scrutiny.port}
        import cloudflare
      '';
    };
  };
}
