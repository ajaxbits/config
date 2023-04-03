let
  audiobooksDir = "/data/audiobooks";
in {
  project.name = "audiobookshelf";
  services = {
    audiobookshelf.service = {
      container_name = "audiobookshelf";
      image = "ghcr.io/advplyr/audiobookshelf:2.2.18";
      restart = "unless-stopped";
      volumes = [
        "${audiobooksDir}/config:/config"
        "${audiobooksDir}/metadata:/metadata"
        "${audiobooksDir}/audiobooks:/audiobooks"
        "${audiobooksDir}/podcasts:/podcasts"
      ];
      ports = ["13378:80"];
    };
  };
}
