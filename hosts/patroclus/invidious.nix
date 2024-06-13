{
  config,
  pkgsUnstable,
  ...
}: {
  config = {
    services.invidious = {
      enable = true;
      package = pkgsUnstable.invidious;

      domain = "https://yt.ajax.casa";
      address = "127.0.0.1";
      port = 3111;

      settings.db.user = "invidious";

      http3-ytproxy = {
        enable = true;
        package = pkgsUnstable.http3-ytproxy;
      };
    };

    systemd.services.http3-ytproxy.serviceConfig.User = config.services.caddy.user;

    services.caddy.virtualHosts = let
      inherit (config.services.invidious) address domain port;
    in {
      "${domain}".extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${address}:${toString port}
        import cloudflare

        @ytproxy path_regexp ytproxy ^/videoplayback|^/vi/|^/ggpht/|^/sb/
        reverse_proxy @ytproxy unix//run/http3-ytproxy/socket/http-proxy.sock
      '';
    };
  };
}
