{host ? null}: {
  config,
  self,
  lib,
  ...
}: let
  audiobookshelfPort = "13378";
in {
  virtualisation.arion.projects.audiobookshelf.settings = import ./arion-compose.nix {
    secretsPath = "${config.age.secretsDir}/libation";
    inherit audiobookshelfPort;
  };

  # Configure groups
  users.users = {
    audiobookshelf = {
      isSystemUser = true;
      group = "audiobookshelf";
    };
    libation = {
      isSystemUser = true;
      group = "libation";
    };
  };
  users.groups = {
    audiobookshelf = {};
    libation = {};
  };

  # auth to Audible
  age.secrets = {
    "libation/Settings.json" = {
      file = "${self}/secrets/libation/Settings.json.age";
      mode = "440";
      owner = "libation";
      group = "libation";
    };
    "libation/AccountsSettings.json" = {
      file = "${self}/secrets/libation/AccountsSettings.json.age";
      mode = "440";
      owner = "libation";
      group = "libation";
    };
  };
  services.caddy.virtualHosts = lib.mkIf (host != null) {
    "${host}".extraConfig = ''
      encode gzip zstd
      reverse_proxy 127.0.0.1:${audiobookshelfPort}
    '';
  };
}
