{ config, ... }:
{
  config = {
    services.scrutiny = {
      enable = true;
      openFirewall = false;
      settings.web.listen.port = 6464;
    };
    services.caddy.virtualHosts."https://disks.ajax.casa" = {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy localhost:${builtins.toString config.services.scrutiny.settings.web.listen.port}
        import cloudflare
      '';
    };
  };
}
