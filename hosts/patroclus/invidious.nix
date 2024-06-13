{
  config,
  pkgsUnstable,
  ...
}: {
  config = {
    services.invidious = {
      enable = true;
      package = pkgsUnstable.invidious;

      domain = "yt.ajax.casa";
      address = "127.0.0.1";
      port = 3111;

      settings = {
        db.user = "invidious";
        https_only = true;
      };

      http3-ytproxy = {
        enable = true;
        package = pkgsUnstable.http3-ytproxy;
      };
    };

    systemd.services.http3-ytproxy = {
      serviceConfig.User = config.services.caddy.user;
      environment.DISABLE_WEBP = "1";
    };

    services.caddy.virtualHosts = let
      inherit (config.services.invidious) address domain port;
    in {
      "https://${domain}".extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${address}:${toString port}
        import cloudflare

        @ytproxy path_regexp ytproxy ^/videoplayback|^/vi/|^/ggpht/|^/sb/
        reverse_proxy @ytproxy unix//run/http3-ytproxy/socket/http-proxy.sock {
            header_up X-Forwarded-For ""
            header_up CF-Connecting-IP ""
            header_down -alt-svc
            header_down -Cache-Control
            header_down -etag

            header_down Cache-Control "private"

            buffer_requests 16MB
            buffer_responses 16MB

            transport http {
                versions 1.1
                keepalive
            }
        }
      '';
    };
  };
}
