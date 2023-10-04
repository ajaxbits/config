{
  config,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:
with lib; let
  cfg = config.components.mediacenter;
  mediaDir = "/data/media";
in {
  options.components.mediacenter = {
    enable = mkEnableOption "Enable mediacenter features";
    intel.enable = mkEnableOption "Enables intel graphics hardware acceleration";
    linux-isos.enable = mkEnableOption "Enable infrastructure for discovering cool Linux ISOs to download.";
    youtube.enable = mkEnableOption "Enable archival of youtube videos";
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
        extraGroups = ["mediaoperators" "configoperators"];
      };
      sonarr = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "sonarr";
        extraGroups = ["mediaoperators" "configoperators"];
      };
      downloader = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "downloader";
        extraGroups = ["mediaoperators" "configoperators"];
      };
      youtube = mkIf cfg.youtube.enable {
        isSystemUser = true;
        group = "youtube";
        extraGroups = ["mediaoperators"];
      };
    };
    users.groups = {
      mediaoperators = {};
      configoperators = {};
      radarr = mkIf cfg.linux-isos.enable {};
      sonarr = mkIf cfg.linux-isos.enable {};
      downloader = mkIf cfg.linux-isos.enable {};
      youtube = mkIf cfg.youtube.enable {};
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
    services.bazarr.enable = mkIf cfg.linux-isos.enable true;
    

    virtualisation.docker.enable = cfg.linux-isos.enable || cfg.youtube.enable;
    environment.systemPackages =
      if cfg.linux-isos.enable
      then [pkgs.docker-compose pkgsUnstable.recyclarr]
      else [];

    virtualisation.oci-containers = mkIf cfg.youtube.enable {
      backend = "docker";
      containers.yt-dlp = {
        image = "ghcr.io/marcopeocchi/yt-dlp-web-ui:latest"; #TODO: pin somehow
        ports = ["3033:3033"];
        volumes = ["${mediaDir}/videos:/downloads"];
        user = config.users.users.youtube.name;
      };
    };
  };
}
