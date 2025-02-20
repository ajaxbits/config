{ config, lib, ... }:
let
  inherit (lib) mkIf;

  domain = "posts.ajax.lol";
in
{
  services = {
    writefreely = {
      enable = true;
      host = domain;
      admin = {
        name = "ajaxbits";
      };
      settings = {
        app = {
          single_user = true;
          site_description = "Alex's blog.";
          site_name = "posts";
          wf_modesty = true;
          open_registration = false;
        };
        server = {
          port = 8155;
        };
      };
    };
    caddy.virtualHosts.${domain} = mkIf config.components.caddy.enable {
      extraConfig = ''
        import cloudflare
        reverse_proxy http://localhost:8155
        encode gzip zstd
      '';
    };
    cloudflared = mkIf config.components.cloudflared.enable {
      tunnels."a5466e3c-1170-4a2a-ae62-1a992509f36f".ingress = {
        ${domain} = {
          service = "https://localhost:443";
          originRequest = {
            originServerName = domain;
            httpHostHeader = domain;
          };
        };
      };
    };
  };
}
