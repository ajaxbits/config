{
  host ? null,
  forgejoPort ? null,
}: {
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  rootUrl =
    if host != null
    then "https://${host}/"
    else "http://0.0.0.0/";
  httpAddress =
    if host != null
    then "127.0.0.1"
    else "0.0.0.0";
  httpPort =
    if forgejoPort != null
    then forgejoPort
    else 3001;
in
  {
    services.gitea = {
      imports = [./settings.nix];
      enable = true; # Enable Gitea
      package = pkgs.forgejo;
      appName = "hephaestus"; # Give the site a name
      database = {
        type = "postgres"; # Database type
        passwordFile = "${config.age.secretsDir}/forgejo/postgresql-pass"; # Where to find the password
      };

      lfs.enable = true; # Enable Git LFS

      domain = host;
      inherit rootUrl;
      inherit httpAddress;
      inherit httpPort;
    };

    services.postgresql = {
      enable = true; # Ensure postgresql is enabled
      authentication = ''
        local gitea all ident map=gitea-users
      '';
      identMap =
        # Map the gitea user to postgresql
        ''
          gitea-users gitea gitea
        '';
    };

    # auth to postgresql
    age.secrets = {
      "forgejo/postgresql-pass" = {
        file = "${self}/secrets/forgejo/postgresql-pass.age";
        mode = "440";
        owner = config.services.gitea.user;
        group = config.services.gitea.user;
      };
    };
  }
  // (
    if host != null
    then {
      services.caddy.virtualHosts."${host}".extraConfig = ''
        encode gzip zstd
        reverse_proxy 127.0.0.1:3001

        forward_auth unix//run/tailscale.nginx-auth.sock {
          uri /auth
          header_up Remote-Addr {remote_host}
          header_up Remote-Port {remote_port}
          header_up Original-URI {uri}
          copy_headers {
            Tailscale-User>X-Webauth-User
            Tailscale-Name>X-Webauth-Name
            Tailscale-Login>X-Webauth-Login
            Tailscale-Tailnet>X-Webauth-Tailnet
            Tailscale-Profile-Picture>X-Webauth-Profile-Picture
          }
        }
      '';
      services.gitea.settings.session.COOKIE_SECURE = true; # Recommended for HTTPS
      services.gitea.settings.service.ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
      services.gitea.settings.service.ENABLE_REVERSE_PROXY_AUTHENTICATION = true;
      services.gitea.settings.service.ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true;
      services.gitea.settings.service.ENABLE_REVERSE_PROXY_EMAIL = true;
      services.gitea.settings.service.ENABLE_REVERSE_PROXY_FULL_NAME = true;
    }
    else null
  )
