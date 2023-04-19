{secretsPath, ...}: let
  audiobooksDir = "/data/audiobooks";
in {
  project.name = "audiobookshelf";
  services = {
    audiobookshelf.service = {
      container_name = "audiobookshelf";
      image = "ghcr.io/advplyr/audiobookshelf:2.2.19";
      restart = "unless-stopped";
      volumes = [
        "${audiobooksDir}/config:/config"
        "${audiobooksDir}/metadata:/metadata"
        "${audiobooksDir}/audiobooks:/audiobooks"
        "${audiobooksDir}/podcasts:/podcasts"
      ];
      ports = ["13378:80"];
    };

    libation-prep.service = {
      contaier_name = "libation-prep";
      user = "root";
      image = {
        enableRecommendedContents = true;
        volumes = [
          "${audiobooksDir}/libation:/config"
          "${secretsPath}/libation:/secrets"
        ];
        command = [
          "/bin/sh"
          "-c"
          "'cp /secrets/Settings.json /config/Settings.json && cp /secrets/AccountSettings.json /config/AccountSettings.json'"
        ];
      };
    };

    libation.service = {
      container_name = "libation";
      depends_on = ["libation-prep"];
      user = "libation";

      image = "rmcrackan/libation:latest";
      restart = "always";
      volumes = [
        "${audiobooksDir}/libation:/config"
        "${audiobooksDir}/audiobooks:/data"
      ];
    };
  };
}
