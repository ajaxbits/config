{
  self,
  config,
  lib,
  inputs,
  ...
}: let
  audiobookshelfVersion = "2.4.3";
  libationVersion = "11.0.4";

  cfg = config.components.audiobookshelf;
in {
  options.components.audiobookshelf = with lib; {
    enable = mkEnableOption "Enable audiobookshelf component.";
    port = mkOption {
      type = types.int;
      description = "Port to listen on.";
      default = 13378;
    };
    audiobooksDir = mkOption {
      type = types.str;
      description = "Directory where audiobooks are";
      default = "/data/audiobooks";
    };
    podcastsDir = mkOption {
      type = types.str;
      description = "Directory where podcasts are";
      default = "/data/podcasts";
    };
    configDir = mkOption {
      type = types.str;
      description = "Directory to store mutable config in";
      default = "/data/config";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.arion.projects.audiobookshelf.settings = {
      services = {
        audiobookshelf.service = {
          user = "audiobookshelf";
          container_name = "audiobookshelf";
          image = "ghcr.io/advplyr/audiobookshelf:${audiobookshelfVersion}";
          restart = "unless-stopped";
          volumes = [
            "${cfg.configDir}/audiobookshelf:/config"
            "${cfg.configDir}/audiobookshelf/metadata:/metadata"
            "${cfg.audiobooksDir}/audiobooks:/audiobooks"
            "${cfg.podcastsDir}/podcasts:/podcasts"
          ];
          ports = ["${builtins.toString cfg.port}:80"];
        };

        libation-prep.service = {
          container_name = "libation-prep";
          user = "root";
          image = "busybox";
          privileged = true;
          volumes = [
            "${cfg.configDir}/libation:/config"
            "${config.age.secretsDir}/libation:/secrets"
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
          user = "libation";
          image = "rmcrackan/libation:${libationVersion}";
          restart = "always";
          volumes = [
            "${cfg.configDir}/libation:/config"
            "${cfg.audiobooksDir}:/data"
          ];
        };
      };
    };

    users.users = {
      audiobookshelf = {
        isSystemUser = true;
        group = "audiobookshelf";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
      };
      libation = {
        isSystemUser = true;
        group = "libation";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
      };
    };
    users.groups = {
      audiobookshelf = {};
      libation = {};
      mediaoperators = {};
      configoperators = {};
    };

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

    virtualisation.docker.enable = false;
    virtualisation.podman.enable = true;
    virtualisation.podman.dockerSocket.enable = true;
    virtualisation.podman.defaultNetwork.settings.dns_enabled = true;
    virtualisation.arion.backend = "podman-socket";
  };
}
