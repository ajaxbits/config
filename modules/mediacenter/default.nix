{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.components.mediacenter;
in {
  options.components.mediacenter.enable = mkEnableOption "Enable mediacenter features";

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "mediaoperators";
      openFirewall = true;
    };

    services.jellyseerr = {
      enable = true;
    };

    users.users = {
      jellyfin = {
        isSystemUser = true;
        group = "mediaoperators";
      };
    };
    users.groups = {
      mediaoperators = {};
    };
  };
}
