{
  config,
  lib,
  pkgsUnstable,
  ...
}: let
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
    address = mkOption {
      type = types.str;
      description = "Address to listen on.";
      default = "0.0.0.0";
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
      requires = ["network.target"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        WorkingDirectory = lib.mkDefault "/var/lib/audiobookshelf";
        ExecStart = "${pkgsUnstable.audiobookshelf}/bin/audiobookshelf --host ${cfg.address} --port ${builtins.toString cfg.port} --config ${cfg.configDir}/audiobookshelf/config --metadata ${cfg.configDir}/audiobookshelf/metadata";
        ExecReload = "kill -HUP $MAINPID";
        Restart = "always";
        User = cfg.user;
        Group = cfg.group;
        StateDirectory = lib.mkDefault "audiobookshelf";
        StateDirectoryMode = "0700";
        ProtectHome = true;
        PrivateDevices = true;
        ProtectHostname = true;
        ProtectClock = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        RemoveIPC = true;
        PrivateMounts = true;
        Type = "simple";
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
    users.users = lib.mkIf (cfg.user == "audiobookshelf") {
      audiobookshelf = {
        isSystemUser = true;
        group = "audiobookshelf";
        extraGroups = ["mediaoperators" "configoperators"];
      };
    };
    users.groups = lib.mkIf (cfg.group == "audiobookshelf") {
      audiobookshelf = {};
      mediaoperators = {};
      configoperators = {};
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
