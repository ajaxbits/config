let
  audiobooksDir = "/data/audiobooks";
in {
  virtualisation.oci-containers.backend = "docker";
  virtualisation.oci-containers.containers = {
  #' exit code is 'exited' and its exit status is 125.
#Apr 02 18:43:42 agamemnon docker-audiobookshelf-post-stop[3708165]: Error: No such container: audiobookshelf
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
