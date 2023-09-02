{host ? null}: {
  config,
  self,
  lib,
  ...
}: let
  audiobookshelfDir = "/data/audiobooks";
  audiobookshelfPort = "13378";
in {
  imports = [
    (import ./backup.nix {
      inherit audiobookshelfDir;
      healthchecks-url = "https://hc-ping.com/e7c85184-7fcf-49a2-ab4f-7fae49a80d9c";
    })
  ];

  virtualisation.arion.projects.audiobookshelf.settings = import ./arion-compose.nix {
    inherit audiobookshelfDir audiobookshelfPort;
    secretsPath = "${config.age.secretsDir}/libation";
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
