{
  config,
  dataPaths,
  lib,
  pkgs,
  pkgsUnstable,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.components.audiobookshelf;
  libationVersion = "12.5.3";
in
{
  imports = [ ./backup.nix ];

  options.components.audiobookshelf = {
    enable = mkEnableOption "Enable audiobookshelf component.";
    port = mkOption {
      type = types.int;
      description = "Port to listen on.";
      default = 13378;
    };
    address = mkOption {
      type = types.str;
      description = "Address to listen on.";
      default = "127.0.0.1";
    };
    audiobooksDir = mkOption {
      type = types.str;
      description = "Directory where audiobooks are";
      default = dataPaths.audiobooks;
    };
    podcastsDir = mkOption {
      type = types.str;
      description = "Directory where podcasts are";
      default = "${dataPaths.media}/podcasts";
    };
    configDir = mkOption {
      type = types.str;
      description = "Directory to store mutable config in";
      default = "${dataPaths.config}/audiobookshelf";
    };
    libationDataDir = mkOption {
      type = types.str;
      description = "Directory to store libation data in";
      default = "${dataPaths.containers}/libation";
    };
    user = mkOption {
      type = types.str;
      description = "User to run audiobookshelf as";
      default = "audiobookshelf";
    };
    group = mkOption {
      type = types.str;
      description = "Group to run audiobookshelf as";
      default = "audiobookshelf";
    };
    backups = {
      enable = mkEnableOption "Enable backups";
      audiobooks.enable = mkOption {
        description = "Enable audiobook file backup";
        type = types.bool;
        default = true;
      };
      metadata.enable = mkOption {
        description = "Enable backup for audiobookshelf metadata files";
        type = types.bool;
        default = true;
      };
      healthchecksUrl = mkOption {
        description = "Healthchecks endpoint for backup monitoring";
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {
    services.audiobookshelf = {
      inherit (cfg)
        enable
        group
        port
        user
        ;
      host = cfg.address;
      package = pkgsUnstable.audiobookshelf;
    };
    systemd = {
      # FIXME: I know. This sux. I will learn what is actually happening one day.
      services.libation-hack =
        let
          script = ''
            set -eux
            ${pkgs.coreutils}/bin/chgrp -R mediaoperators ${cfg.audiobooksDir}
            ${pkgs.coreutils}/bin/chmod -R g+rw ${cfg.audiobooksDir}
          '';
        in
        {
          inherit script;
          description = "Horrible hack to set unix permissions for libation-liberated files on a schedule.";
          serviceConfig.User = "root";
        };
      timers.libation-hack = {
        description = "Horrible hack to set unix permissions for libation-liberated files on a schedule.";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "*:0/30";
          WakeSystem = true;
          Persistent = true;
        };
      };
    };
    users.users = mkIf (cfg.user == "audiobookshelf") {
      audiobookshelf = {
        isSystemUser = true;
        group = "audiobookshelf";
        extraGroups = [
          "mediaoperators"
          "configoperators"
        ];
        uid = 986;
      };
    };
    users.groups = mkIf (cfg.group == "audiobookshelf") {
      audiobookshelf.gid = 983;
      mediaoperators.gid = 986;
      configoperators.gid = 982;
    };

    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.libation = {
      image = "rmcrackan/libation:${libationVersion}";
      environment.SLEEP_TIME = "10m";
      volumes = [
        "${cfg.audiobooksDir}:/data"
        "${cfg.libationDataDir}:/config"
      ];
    };
    services = {
      caddy.virtualHosts = mkIf config.components.caddy.enable {
        "https://audiobooks.ajax.casa".extraConfig = ''
          encode gzip zstd
          reverse_proxy http://${cfg.address}:${builtins.toString cfg.port}
          import cloudflare
        '';
        "https://audiobooks.ajax.lol".extraConfig = ''
          encode gzip zstd
          reverse_proxy http://${cfg.address}:${builtins.toString cfg.port}
          import cloudflare
        '';
      };

      cloudflared = mkIf config.components.cloudflared.enable {
        tunnels."a5466e3c-1170-4a2a-ae62-1a992509f36f".ingress =
          let
            url = "audiobooks.ajax.lol";
          in
          {
            ${url} = {
              service = "https://localhost:443";
              originRequest = {
                originServerName = url;
                httpHostHeader = url;
              };
            };
          };
      };
    };
  };
}
