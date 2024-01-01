{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOverride;
  cfg = config.components.photos;

  version = "1.91.4";
in {
  config = mkIf cfg.enable {
    # Runtime
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    # Containers
    virtualisation.oci-containers.containers."immich_machine_learning" = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}";

      environmentFiles = [config.age.secrets."immich/.env".path];
      environment.IMMICH_VERSION = version;

      volumes = ["model-cache:/cache:rw"];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=immich-machine-learning"
        "--network=immich-default"
      ];
    };
    systemd.services."docker-immich_machine_learning" = {
      serviceConfig = {
        Restart = mkOverride 500 "always";
      };
      after = [
        "docker-network-immich-default.service"
        "docker-volume-model-cache.service"
      ];
      requires = [
        "docker-network-immich-default.service"
        "docker-volume-model-cache.service"
      ];
      partOf = [
        "docker-compose-immich-root.target"
      ];
      wantedBy = [
        "docker-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich_microservices" = {
      image = "ghcr.io/immich-app/immich-server:${version}";

      environmentFiles = [config.age.secrets."immich/.env".path];
      environment.IMMICH_VERSION = version;

      volumes = [
        "/data/media/photos:/usr/src/app/upload:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      cmd = ["start.sh" "microservices"];
      dependsOn = [
        "immich_postgres"
        "immich_redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=immich-microservices"
        "--network=immich-default"
      ];
    };
    systemd.services."docker-immich_microservices" = {
      serviceConfig = {
        Restart = mkOverride 500 "always";
      };
      after = [
        "docker-network-immich-default.service"
      ];
      requires = [
        "docker-network-immich-default.service"
      ];
      partOf = [
        "docker-compose-immich-root.target"
      ];
      unitConfig.UpheldBy = [
        "docker-immich_postgres.service"
        "docker-immich_redis.service"
      ];
      wantedBy = [
        "docker-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich_postgres" = {
      image = "tensorchord/pgvecto-rs:pg14-v0.1.11@sha256:0335a1a22f8c5dd1b697f14f079934f5152eaaa216c09b61e293be285491f8ee";

      environmentFiles = [config.age.secrets."immich/.env".path];
      environment.IMMICH_VERSION = version;

      volumes = [
        "pgdata:/var/lib/postgresql/data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=database"
        "--network=immich-default"
      ];
    };
    systemd.services."docker-immich_postgres" = {
      serviceConfig = {
        Restart = mkOverride 500 "always";
      };
      after = [
        "docker-network-immich-default.service"
        "docker-volume-pgdata.service"
      ];
      requires = [
        "docker-network-immich-default.service"
        "docker-volume-pgdata.service"
      ];
      partOf = [
        "docker-compose-immich-root.target"
      ];
      wantedBy = [
        "docker-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich_redis" = {
      image = "redis:6.2-alpine@sha256:b6124ab2e45cc332e16398022a411d7e37181f21ff7874835e0180f56a09e82a";
      log-driver = "journald";
      extraOptions = [
        "--network-alias=redis"
        "--network=immich-default"
      ];
    };
    systemd.services."docker-immich_redis" = {
      serviceConfig = {
        Restart = mkOverride 500 "always";
      };
      after = [
        "docker-network-immich-default.service"
      ];
      requires = [
        "docker-network-immich-default.service"
      ];
      partOf = [
        "docker-compose-immich-root.target"
      ];
      wantedBy = [
        "docker-compose-immich-root.target"
      ];
    };
    virtualisation.oci-containers.containers."immich_server" = {
      image = "ghcr.io/immich-app/immich-server:${version}";

      environmentFiles = [config.age.secrets."immich/.env".path];
      environment.IMMICH_VERSION = version;

      volumes = [
        "/data/media/photos:/usr/src/app/upload:rw"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports = [
        "2283:3001/tcp"
      ];
      cmd = ["start.sh" "immich"];
      dependsOn = [
        "immich_postgres"
        "immich_redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=immich-server"
        "--network=immich-default"
      ];
    };
    systemd.services."docker-immich_server" = {
      serviceConfig = {
        Restart = mkOverride 500 "always";
      };
      after = [
        "docker-network-immich-default.service"
      ];
      requires = [
        "docker-network-immich-default.service"
      ];
      partOf = [
        "docker-compose-immich-root.target"
      ];
      unitConfig.UpheldBy = [
        "docker-immich_postgres.service"
        "docker-immich_redis.service"
      ];
      wantedBy = [
        "docker-compose-immich-root.target"
      ];
    };

    # Networks
    systemd.services."docker-network-immich-default" = {
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.docker}/bin/docker network rm -f immich-default";
      };
      script = ''
        docker network inspect immich-default || docker network create immich-default
      '';
      partOf = ["docker-compose-immich-root.target"];
      wantedBy = ["docker-compose-immich-root.target"];
    };

    # Volumes
    systemd.services."docker-volume-model-cache" = {
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        docker volume inspect model-cache || docker volume create model-cache
      '';
      partOf = ["docker-compose-immich-root.target"];
      wantedBy = ["docker-compose-immich-root.target"];
    };
    systemd.services."docker-volume-pgdata" = {
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        docker volume inspect pgdata || docker volume create pgdata
      '';
      partOf = ["docker-compose-immich-root.target"];
      wantedBy = ["docker-compose-immich-root.target"];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."docker-compose-immich-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = ["multi-user.target"];
    };

    age.secrets."immich/.env".file = "${self}/secrets/immich/.env.age";
  };
}
