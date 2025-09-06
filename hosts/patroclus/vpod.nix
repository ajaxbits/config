{ config, ... }:
let
  domain = "podcasts.ajax.lol";
  baseUrl = "https://${domain}";
in
{
  config = {
    components = {
      caddy = {
        enable = true;
        cloudflare.enable = true;
      };
      cloudflared.enable = true;
    };

    services = {
      vpod = {
        enable = true;
        settings = {
          inherit baseUrl;
          frontend.passwordFile = config.age.secrets."vpod/passwordfile".path;
          port = 9989;
        };
      };

      cloudflared.tunnels."a5466e3c-1170-4a2a-ae62-1a992509f36f".ingress.${domain} = {
        service = "https://localhost:443";
        originRequest = {
          originServerName = domain;
          httpHostHeader = domain;
        };
      };
      caddy.virtualHosts.${baseUrl} = {
        extraConfig = ''
          encode gzip zstd
          reverse_proxy ${config.services.vpod.settings.host}:${builtins.toString config.services.vpod.settings.port}
          import cloudflare
        '';
      };
    };

    age.secrets."vpod/passwordfile" = {
      file = ../../secrets/vpod/passwordfile.age;
      mode = "440";
      owner = config.services.vpod.user;
      inherit (config.services.vpod) group;
    };
  };
}
