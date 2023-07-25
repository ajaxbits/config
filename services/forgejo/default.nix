{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  rootUrl = "http://0.0.0.0/";
  httpAddress = "0.0.0.0";
  httpPort = 3001;
in {
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

    host = "agamemnon";
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
  users.users = {
    gitea = {
      isSystemUser = true;
      group = "gitea";
    };
  };
  users.groups = {
    gitea = {};
  };
  age.secrets = {
    "forgejo/postgresql-pass" = {
      file = "${self}/secrets/forgejo/postgresql-pass.age";
      mode = "440";
      owner = config.services.gitea.user;
      group = config.services.gitea.user;
    };
  };
}
