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
        email.from = "nobody@nobody.com";
        disable_startup_analytics = true;
        avatars = "initials";
      };
    };

    caddy.virtualHosts."auth.ajax.lol" = mkIf config.components.caddy.enable {
      extraConfig = ''
        import cloudflare
        reverse_proxy :${toString port}
      '';
    };
  };

  users.users.authentik = {
    isSystemUser = true;
    group = "authentik";
  };
  users.groups.authentik = { };

  age.secrets = {
    "authentik/env" = {
      file = "${self}/secrets/authentik/env.age";
      mode = "440";
      owner = "authentik";
      group = "authentik";
    };
  };
}
