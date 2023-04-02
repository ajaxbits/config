let
  audiobooksDir = "/data/audiobooks";
in {
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
    audiobookshelf = {
      image = "ghcr.io/advplyr/audiobookshelf";
      volumes = [
        "${audiobooksDir}/config:/config"
        "${audiobooksDir}/metadata:/metadata"
        "${audiobooksDir}/audiobooks:/audiobooks"
        "${audiobooksDir}/podcasts:/podcasts"
      ];
      ports = ["13378:13378"];
      user = "audiobookshelf:audiobookshelf";
    };
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
