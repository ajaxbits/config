{
  config,
  pkgs,
  lib,
  self,
  configDir,
  port,
  public ? false,
  ...
}: let
  endpoint =
    if public
    then "0.0.0.0:${toString port}"
    else "127.0.0.1:${toString port}";
in {
  config = {
    users = rec {
      users.linkding = {
        group = groups.linkding.name;
        extraGroups = [groups.configoperators.name];
      };
      groups = {
        configoperators = {};
        linkding = {};
      };
    };

    virtualisation = {
      docker = {
        enable = true;
        autoPrune.enable = true;
      };
      oci-containers.backend = "docker";

      oci-containers.containers."linkding" = {
        image = "sissbruecker/linkding:latest";
        user = config.users.users.linkding.name;
        environment = {
          LD_CONTAINER_NAME = "linkding";
          LD_DISABLE_BACKGROUND_TASKS = "False";
          LD_DISABLE_URL_VALIDATION = "False";
          LD_ENABLE_AUTH_PROXY = "False";
          LD_HOST_DATA_DIR = "${configDir}/linkding";
          LD_HOST_PORT = toString port;
        };
        environmentfiles = ["${config.age.secretsDir}/linkding/.env"];
        volumes = ["${configDir}/linkding:/etc/linkding/data:rw"];
        ports = ["${endpoint}:9090/tcp"];
        log-driver = "journald";
        extraOptions = [
          "--network-alias=linkding"
          "--network=linkding_default"
        ];
      };
    };

    systemd = {
      services."docker-linkding" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = ["docker-network-linkding_default.service"];
        requires = ["docker-network-linkding_default.service"];
        partOf = ["docker-compose-linkding-root.target"];
        wantedBy = ["docker-compose-linkding-root.target"];
      };

      services."docker-network-linkding_default" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f linkding_default";
        };
        script = ''
          docker network inspect linkding_default || docker network create linkding_default
        '';
        partOf = ["docker-compose-linkding-root.target"];
        wantedBy = ["docker-compose-linkding-root.target"];
      };

      targets."docker-compose-linkding-root" = {
        unitConfig = {
          Description = "Root target generated by compose2nix.";
        };
        wantedBy = ["multi-user.target"];
      };
    };

    age.secrets = {
      "linkding/.env" = {
        file = "${self}/secrets/linkding/.env.age";
        mode = "440";
        owner = config.users.users.linkding.name;
        inherit (config.users.users.linkding) group;
      };
    };
  };
}