{
  config,
  lib,
  ...
}: let
  cfg = config.components.analytics;
in {
  options.components.analytics = with lib; {
    enable = mkEnableOption "Enable web analytics framework.";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.backend = "docker";
    virtualisation.oci-containers.containers.umami = {
      image = "ghcr.io/umami-software/umami:postgresql-latest";
      ports = ["127.0.0.1:4119:3000"];
    };

    users.users = {
      analytics = {
        isSystemUser = true;
        group = "analytics";
      };
    };
    users.groups = {
      analytics = {};
    };
  };
}
