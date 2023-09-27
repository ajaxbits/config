{
  self,
  config,
  lib,
  pkgs,
  unstablePkgs,
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
      default = "/data/media/audiobooks";
    };
    podcastsDir = mkOption {
      type = types.str;
      description = "Directory where podcasts are";
      default = "/data/media/podcasts";
    };
    configDir = mkOption {
      type = types.str;
      description = "Directory to store mutable config in";
      default = "/data/config";
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
  };

  config = lib.mkIf cfg.enable {
    systemd.services.audiobookshelf = {
      description = "Audiobookshelf";
      after = ["network.target"];
      wantedBy = ["multi-user.target"];
      environment = {
        HOST = cfg.hostname;
        PORT = toString cfg.port;
        NODE_ENV = "production";
        CONFIG_PATH = "${cfg.dataDir}/config";
        METADATA_PATH = "${cfg.dataDir}/metadata";
        FFMPEG_PATH = "${pkgs.ffmpeg-full}/bin/ffmpeg";
        FFPROBE_PATH = "${pkgs.ffmpeg-full}/bin/ffprobe";
        TONE_PATH = "${pkgs.tone}/bin/tone";
        SOURCE = "nixpkgs";
      };
      path = [
        pkgs.nodejs_18
        pkgs.util-linux
      ];
      serviceConfig = {
        WorkingDirectory = lib.mkDefault "/var/lib/audiobookshelf";
        ExecStart = "exec node ${unstablePkgs.audiobookshelf}/opt/index.js";
        ExecReload = "kill -HUP $MAINPID";
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = lib.mkDefault "audiobookshelf";
        StateDirectoryMode = "0700";
        ProtectHome = true;
        ProtectSystem = "strict";
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        Type = "simple";
        UMask = "0077";
        TimeoutSec = 15;
        NoNewPrivileges = true;
        SystemCallArchitectures = "native";
        RestrictNamespaces = !config.boot.isContainer;
        ProtectControlGroups = !config.boot.isContainer;
        ProtectKernelLogs = !config.boot.isContainer;
        ProtectKernelModules = !config.boot.isContainer;
        ProtectKernelTunables = !config.boot.isContainer;
        LockPersonality = true;
        PrivateTmp = !config.boot.isContainer;
        SystemCallFilter = [
          "~@clock"
          "~@aio"
          "~@chown"
          "~@cpu-emulation"
          "~@debug"
          "~@keyring"
          "~@memlock"
          "~@module"
          "~@mount"
          "~@obsolete"
          "~@privileged"
          "~@raw-io"
          "~@reboot"
          "~@setuid"
          "~@swap"
        ];
        SystemCallErrorNumber = "EPERM";
      };
    };
    users.users = lib.mkIf (cfg.user != "audiobookshelf") {
      audiobookshelf = {
        isSystemUser = true;
        group = "audiobookshelf";
        extraGroups = ["mediaoperators"];
      };
    };
    users.groups = lib.mkIf (cfg.group != "audiobookshelf") {
      audiobookshelf = {};
      mediaoperators = {};
    };

    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.libation = {
      image = "rmcrackan/libation:${libationVersion}";
      volumes = [
        "${cfg.audiobooksDir}:/data"
        "${cfg.configDir}/libation:/config"
      ];
    };
  };
}
