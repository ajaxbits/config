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
    virtualisation.podman.enable = true;
    virtualisation.podman.dockerCompat = true;

    virtualisation.oci-containers.containers.libation = {
      image = "rmcrackan/libation:${libationVersion}";
      volumes = [
        "${cfg.audiobooksDir}:/data"
        "${cfg.configDir}/libation:/config"
      ];
    };
  };
}
