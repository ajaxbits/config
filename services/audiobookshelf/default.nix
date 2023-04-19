{
  config,
  self,
  ...
}: {
  virtualisation.arion.projects.audiobookshelf.settings = import ./arion-compose.nix {secretsPath = config.age.secretsDir;};

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
}
