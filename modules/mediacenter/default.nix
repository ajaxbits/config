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
    linux-isos.enable = mkEnableOption "Enable infrastructure for discovering cool Linux ISOs to download.";
  };

  config = mkIf cfg.enable {
    services.jellyfin = {
      enable = true;
      user = "jellyfin";
      group = "mediaoperators";
      openFirewall = true;
    };

    users.users = {
      jellyfin = {
        isSystemUser = true;
        group = "mediaoperators";
      };
      radarr = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "radarr";
        extraGroups = ["mediaoperators"];
      };
      sonarr = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "sonarr";
        extraGroups = ["mediaoperators"];
      };
      downloader = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "downloader";
        extraGroups = ["mediaoperators" "configoperators"];
      };
    };
    users.groups = {
      mediaoperators = {};
      configoperators = {};
      radarr = {};
      sonarr = {};
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

    services.sonarr = mkIf cfg.linux-isos.enable {
      enable = true;
      user = "sonarr";
      openFirewall = true;
    };
    services.radarr = mkIf cfg.linux-isos.enable {
      enable = true;
      user = "radarr";
      openFirewall = true;
    };
    services.prowlarr = mkIf cfg.linux-isos.enable {
      enable = true;
      openFirewall = true;
    };
    services.bazarr.enable = true;
    services.jellyseerr = mkIf cfg.linux-isos.enable {
      enable = true;
      openFirewall = true;
    };

    virtualisation.docker.enable = true;
    environment.systemPackages = [pkgs.docker-compose];
  };
}
