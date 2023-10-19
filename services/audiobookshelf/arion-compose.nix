{
  secretsPath,
  audiobookshelfDir,
  audiobookshelfPort,
  ...
}: let
  audiobookshelfVersion = "2.4.3";
  libationVersion = "11.1";
in {
  project.name = "audiobookshelf";
  services = {
    audiobookshelf.service = {
      container_name = "audiobookshelf";
      image = "ghcr.io/advplyr/audiobookshelf:${audiobookshelfVersion}";
      restart = "unless-stopped";
      volumes = [
        "${audiobookshelfDir}/config:/config"
        "${audiobookshelfDir}/metadata:/metadata"
        "${audiobookshelfDir}/audiobooks:/audiobooks"
        "${audiobookshelfDir}/podcasts:/podcasts"
      ];
      ports = ["${audiobookshelfPort}:80"];
    };

    libation-prep.service = {
      container_name = "libation-prep";
      user = "root";
      image = "busybox";
      privileged = true;
      volumes = [
        "${audiobookshelfDir}/libation:/config"
        "${secretsPath}:/secrets"
      ];
      command = [
        "/bin/sh"
        "-c"
        "'cp /secrets/Settings.json /config/Settings.json && cp secrets/AccountsSettings.json /config/AccountsSettings.json'"
      ];
    };

    libation.service = {
      container_name = "libation";
      depends_on = ["libation-prep"];
      user = "root";
      image = "rmcrackan/libation:${libationVersion}";
      restart = "always";
      volumes = [
        "${audiobookshelfDir}/libation:/config"
        "${audiobookshelfDir}/audiobooks:/data"
      ];
    };
  };
}
