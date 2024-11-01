{
  config,
  lib,
  pkgs,
  pkgsUnstable,
  unstable,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf optionals;

  cfg = config.components.mediacenter;
in
{
  options.components.mediacenter = {
    enable = mkEnableOption "Enable mediacenter features";
    intel.enable = mkEnableOption "Enables intel graphics hardware acceleration";
    linux-isos.enable = mkEnableOption "Enable infrastructure for discovering cool Linux ISOs to download.";
    youtube.enable = mkEnableOption "Enable archival of youtube videos";
    invidious.enable = mkEnableOption "Enable Invidious instance.";
  };

  imports = [
    ./invidious
    "${unstable}/nixos/modules/services/misc/jellyseerr.nix"
  ];
  disabledModules = [ "services/misc/jellyseerr.nix" ]; # TODO: remove once package opt merged

  config = mkIf cfg.enable {
    services = {
      jellyfin = {
        enable = true;
        user = "jellyfin";
        group = "mediaoperators";
        openFirewall = true;
      };

      sonarr = mkIf cfg.linux-isos.enable {
        enable = true;
        user = "sonarr";
        openFirewall = true;
      };
      radarr = mkIf cfg.linux-isos.enable {
        enable = true;
        user = "radarr";
        openFirewall = true;
      };
      prowlarr = mkIf cfg.linux-isos.enable {
        enable = true;
        openFirewall = true;
      };
      bazarr = lib.mkIf cfg.linux-isos.enable {
        enable = true;
        user = "bazarr";
        group = "bazarr";
      };
      jellyseerr = lib.mkIf cfg.linux-isos.enable {
        enable = false; # TODO: enable once 2.0.1 is avail on nixpkgs
        openFirewall = true;
        package = pkgsUnstable.jellyseerr;
      };

      caddy = lib.mkIf config.components.caddy.enable {
        virtualHosts =
          let
            endpoints = [
              {
                host = "movies";
                port = 7878;
              }
              {
                host = "shows";
                port = 8989;
              }
              {
                host = "subtitles";
                port = config.services.bazarr.listenPort;
              }
              {
                host = "indexers";
                port = 9696;
              }
              {
                host = "bubflix";
                port = 8096;
              }
              {
                host = "jellyfin";
                port = 8096;
              }
              {
                host = "downloads";
                port = 9091;
              }
              {
                host = "podcasts";
                port = 8010;
              }
              {
                host = "requests";
                port = 5055;
              }
            ];

            createReverseProxy = attr: {
              "https://${attr.host}.ajax.casa".extraConfig = ''
                import cloudflare
                reverse_proxy http://localhost:${toString attr.port}
              '';
            };
          in
          builtins.foldl' (a: b: a // b) { } (map createReverseProxy endpoints);
      };
    };
    systemd.services.jellyfin.path = [ pkgs.yt-dlp ]; # required for yt metadata

    users.users = {
      jellyfin = {
        isSystemUser = true;
        group = "mediaoperators";
      };
      bazarr = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "bazarr";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
      };
      radarr = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "radarr";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
      };
      sonarr = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "sonarr";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
      };
      downloader = mkIf cfg.linux-isos.enable {
        isSystemUser = true;
        group = "downloader";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
      };
      youtube = mkIf cfg.youtube.enable {
        isSystemUser = true;
        group = "youtube";
        extraGroups = [ "mediaoperators" ];
      };
    };
    users.groups = {
      mediaoperators = { };
      configoperators = { };
      radarr = mkIf cfg.linux-isos.enable { };
      sonarr = mkIf cfg.linux-isos.enable { };
      bazarr = mkIf cfg.linux-isos.enable { };
      downloader = mkIf cfg.linux-isos.enable { };
      youtube = mkIf cfg.youtube.enable { };
    };

    hardware.opengl = mkIf cfg.intel.enable {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vaapi-intel-hybrid
        vaapiVdpau
        libvdpau-va-gl
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      ];
    };

    virtualisation.docker.enable = cfg.linux-isos.enable || cfg.youtube.enable;
    environment.systemPackages = optionals cfg.linux-isos.enable [
      pkgs.docker-compose
      pkgsUnstable.recyclarr
    ];
  };
}
