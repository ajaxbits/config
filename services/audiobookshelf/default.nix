{
  virtualisation.arion.projects.audiobookshelf.settings = {
    imports = [./arion-compose.nix];
  };

  # Configure groups
  users.users = {
    audiobookshelf = {
      isSystemUser = true;
      group = "audiobookshelf";
    };
  };
  users.groups = {
    audiobookshelf = {};
  };
}
