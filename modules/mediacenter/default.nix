{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.mediacenter;
in {
  options.components.mediacenter = {
    enable = mkEnableOption "Enable mediacenter features";
    intel.enable = mkEnableOption "Enables intel graphics hardware acceleration";
  };

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

    nixpkgs.config = mkIf cfg.intel.enable {
      packageOverrides = pkgs: {
        vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
      };
    };
    hardware.opengl = mkIf cfg.intel.enable {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapiIntel
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };
  };
}
