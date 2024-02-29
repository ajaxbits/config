{
  config,
  lib,
  self,
  pkgsUnstable,
  ...
}: let
  inherit (lib) mkIf;
  cfg = config.components.development.forge;

  user = "forgejo";
  group = "forgejo";
  domain = "git.ajax.casa";
in {
  config = mkIf cfg.enable {
    services.forgejo = {
      inherit user group;
      enable = true;
      lfs.enable = true;
      package = pkgsUnstable.forgejo;
      settings = import ./settings.nix {inherit domain;};
      database = {
        type = "postgres";
        passwordFile = config.age.secrets."forgejo/postgresql-pass".path;
      };
    };

    services.caddy.virtualHosts."https://${domain}" = mkIf config.components.caddy.enable {
      extraConfig =
        ''
          encode gzip zstd
          reverse_proxy http://${config.services.forgejo.settings.server.HTTP_ADDR}:${toString config.services.forgejo.settings.server.HTTP_PORT}
        ''
        + (
          if config.components.caddy.cloudflare.enable
          then ''
            import cloudflare
          ''
          else ''
            tls internal
          ''
        );
    };

    users.users.${user} = {
      inherit group;
      isSystemUser = true;
    };
    users.groups.${group} = {};

    age.secrets = {
      "forgejo/postgresql-pass" = {
        file = "${self}/secrets/forgejo/postgresql-pass.age";
        mode = "440";
        owner = config.users.users.forgejo.name;
        inherit (config.users.users.forgejo) group;
      };
    };
  };
}
