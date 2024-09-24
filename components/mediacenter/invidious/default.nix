{
  lib,
  config,
  self,
  pkgsUnstable,
  ...
}:
let
  inherit (lib) mkIf optionalString;

  cfg = config.components.mediacenter.invidious;
  caddyEnabled = config.components.caddy.enable;

  user = "invidious";
  group = user;
in
{
  config = mkIf cfg.enable {
    services.invidious = {
      enable = true;
      package = pkgsUnstable.invidious;

      domain = optionalString caddyEnabled "yt.ajax.casa";
      address = if caddyEnabled then "127.0.0.1" else "0.0.0.0";
      port = 3111;

      settings = {
        db.user = user;
        https_only = caddyEnabled;
        external_port = optionalString caddyEnabled 443;
        popular_enabled = false;
      };

      extraSettingsFile = config.age.secrets."invidious/extraSettingsFile".path;

      http3-ytproxy = {
        enable = true;
        package = pkgsUnstable.http3-ytproxy;
      };
    };

    systemd.services = {
      http3-ytproxy = {
        serviceConfig.User = mkIf caddyEnabled config.services.caddy.user;
        environment.DISABLE_WEBP = "1";
      };
      invidious.serviceConfig = {
        User = user;
        Group = group;
      };
    };

    users.users.${user} = {
      inherit group;
      isSystemUser = true;
    };
    users.groups.${group} = { };

    services.caddy.virtualHosts = mkIf caddyEnabled (
      let
        inherit (config.services.invidious) address domain port;
      in
      {
        "https://${domain}".extraConfig = ''
          encode gzip zstd
          reverse_proxy http://${address}:${toString port}
          import cloudflare

          log {
              output discard
          }

          @ytproxy path_regexp ytproxy ^/videoplayback|^/vi/|^/ggpht/|^/sb/
          reverse_proxy @ytproxy unix//run/http3-ytproxy/socket/http-proxy.sock {
              header_up X-Forwarded-For ""
              header_up CF-Connecting-IP ""
              header_down -alt-svc
              header_down -Cache-Control
              header_down -etag
              header_down Cache-Control "private"
              transport http {
                  versions 1.1
              }
          }
        '';
      }
    );

    age.secrets = {
      "invidious/extraSettingsFile" = {
        file = "${self}/secrets/invidious/extraSettingsFile.age";
        mode = "440";
        owner = user;
        inherit group;
      };
    };
  };
}
