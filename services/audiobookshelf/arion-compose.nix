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
      container_name = "libation-prep";
      user = "root";
      image = "busybox";
      privileged = true;
      volumes = [
        "${audiobooksDir}/libation:/config"
      ];
      command = [
        "/bin/sh"
        "-c"
        "'ln -sf /run/agenix/libation/Settings.json /config/Settings.json && ln -sf /run/agenix/libation/AccountsSettings.json /config/AccountsSettings.json'"
      ];
    };

    libation.service = {
      container_name = "libation";
      depends_on = ["libation-prep"];
      user = "root";
      image = "rmcrackan/libation:10.2.1";
      restart = "always";
      volumes = [
        "${audiobooksDir}/libation:/config"
        "${audiobooksDir}/audiobooks:/data"
      ];
    };
  };
}
