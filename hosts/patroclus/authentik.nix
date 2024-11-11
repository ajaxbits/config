{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkIf;
  port = 9000;
in
{
  services = {
    authentik = {
      enable = true;
      environmentFile = config.age.secrets."authentik/env".path;
      settings = {
        avatars = "initials";
        disable_startup_analytics = true;
        email = {
          use_ssl = true;
          use_tls = false;
        };
      };
    };

    caddy.virtualHosts."auth.ajax.lol" = mkIf config.components.caddy.enable {
      extraConfig = ''
        import cloudflare
        reverse_proxy :${toString port}
      '';
    };

    cloudflared = mkIf config.components.cloudflared.enable {
      tunnels."a5466e3c-1170-4a2a-ae62-1a992509f36f".ingress =
        let
          url = "auth.ajax.lol";
        in
        {
          ${url} = {
            service = "https://localhost:443";
            originRequest = {
              originServerName = url;
              httpHostHeader = url;
            };
          };
        };
    };
  };

  users = {
    users.authentik = {
      isSystemUser = true;
      group = "authentik";
    };
    groups.authentik = { };
  };

  age.secrets."authentik/env" = {
    file = "${self}/secrets/authentik/env.age";
    mode = "440";
    owner = "authentik";
    group = "authentik";
  };
}
