# Auto-generated using compose2nix v0.1.5.
{
  config,
  pkgs,
  lib,
  self,
  ...
}: let
  uploadLocation = "/data/photos";
in {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };
  virtualisation.oci-containers.backend = "docker";

  virtualisation.oci-containers.containers."immich_machine_learning" = {
    image = "ghcr.io/immich-app/immich-machine-learning:release";
    environmentFiles = [config.age.secrets."immich/.env".path];
    volumes = [
      "model-cache:/cache:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=immich-machine-learning"
      "--network=immich-default"
    ];
  };
  systemd.services."docker-immich_machine_learning" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
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
    image = "ghcr.io/immich-app/immich-server:release";
    environmentFiles = [config.age.secrets."immich/.env".path];
    volumes = [
      "${uploadLocation}:/usr/src/app/upload:rw"
      "/etc/localtime:/etc/localtime:ro"
    ];
    dependsOn = [
      "immich_postgres"
      "immich_redis"
      "immich_typesense"
    ];
    log-driver = "journald";
    extraOptions = [
      "--device=/dev/dri:/dev/dri"
      "--network-alias=immich-microservices"
      "--network=immich-default"
    ];
  };
  systemd.services."docker-immich_microservices" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
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
  virtualisation.oci-containers.containers."immich_postgres" = {
    image = "postgres:14-alpine@sha256:50d9be76e9a90da4c781554955e0ffc79d9d5c4226838e64b36aacc97cbc35ad";
    environmentFiles = [config.age.secrets."immich/.env".path];
    environment = {
      POSTGRES_DB = "\${DB_DATABASE_NAME}";
      POSTGRES_PASSWORD = "\${DB_PASSWORD}";
      POSTGRES_USER = "\${DB_USERNAME}";
    };
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
      Restart = lib.mkOverride 500 "always";
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
    image = "redis:6.2-alpine@sha256:80cc8518800438c684a53ed829c621c94afd1087aaeb59b0d4343ed3e7bcf6c5";
    log-driver = "journald";
    extraOptions = [
      "--network-alias=redis"
      "--network=immich-default"
    ];
  };
  systemd.services."docker-immich_redis" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
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
    image = "ghcr.io/immich-app/immich-server:release";
    environmentFiles = [config.age.secrets."immich/.env".path];
    volumes = [
      "${uploadLocation}:/usr/src/app/upload:rw"
      "/etc/localtime:/etc/localtime:ro"
    ];
    ports = [
      "2283:3001/tcp"
    ];
    dependsOn = [
      "immich_postgres"
      "immich_redis"
      "immich_typesense"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=immich-server"
      "--network=immich-default"
    ];
  };
  systemd.services."docker-immich_server" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
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
  virtualisation.oci-containers.containers."immich_typesense" = {
    image = "typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd";
    environmentFiles = [config.age.secrets."immich/.env".path];
    environment = {
      GLOG_minloglevel = "1";
      TYPESENSE_DATA_DIR = "/data";
    };
    volumes = [
      "tsdata:/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=typesense"
      "--network=immich-default"
    ];
  };
  systemd.services."docker-immich_typesense" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "docker-network-immich-default.service"
      "docker-volume-tsdata.service"
    ];
    requires = [
      "docker-network-immich-default.service"
      "docker-volume-tsdata.service"
    ];
    partOf = [
      "docker-compose-immich-root.target"
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
  systemd.services."docker-volume-tsdata" = {
    path = [pkgs.docker];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      docker volume inspect tsdata || docker volume create tsdata
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

  age.secrets = {
    "immich/.env" = {
      file = "${self}/secrets/immich/.env.age";
      mode = "440";
      owner = config.users.users.root.name;
      group = config.users.users.root.group;
    };
  };
}
