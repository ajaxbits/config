{
  config,
  pkgs,
  lib,
  configDir ? "/srv",
  mediaDir ? "/media",
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkEnableOption
    mkOverride
    types
    ;
  cfg = config.components.photos;

  version = "v1.91.4";

  url = "https://photos.ajax.casa";
  port = 2283;

  nonStorePath = types.pathWith {
    inStore = false;
    absolute = true;
  };
in
{
  options.components.photos = {
    enable = mkEnableOption "Enable photo management";
    dataDir = mkOption {
      type = nonStorePath;
      default = configDir;
      description = "Where the immich data is stored.";
    };
    mediaDir = mkOption {
      type = nonStorePath;
      default = mediaDir;
      description = "Where the photos are stored.";
    };
  };

  config = mkIf cfg.enable {
    virtualisation = {
      # Runtime
      docker = {
        enable = true;
        autoPrune.enable = true;
      };
      oci-containers = {
        backend = "docker";
        containers =
          let
            mkContainer =
              {
                image,
                netAlias,
                ports ? [ ],
                volumes ? [
                  "${cfg.mediaDir}/photos:/usr/src/app/upload:rw"
                  "/etc/localtime:/etc/localtime:ro"
                ],
                needsDb ? false,
                needsSecrets ? true,
              }:
              {
                inherit image volumes ports;

                environment.IMMICH_VERSION = version;

                log-driver = "journald";

                extraOptions = [
                  "--network-alias=${netAlias}"
                  "--network=immich-default"
                ];
              }
              // lib.optionalAttrs needsDb {
                dependsOn = [
                  "immich_postgres"
                  "immich_redis"
                ];
              }
              // lib.optionalAttrs needsSecrets {
                environmentFiles = [ config.age.secrets."immich/.env".path ];
              };
          in
          {
            "immich_machine_learning" = mkContainer {
              image = "ghcr.io/immich-app/immich-machine-learning:${version}";
              netAlias = "immich-machine-learning";
              volumes = [ "model-cache:/cache:rw" ];
            };
            "immich_microservices" = mkContainer {
              image = "ghcr.io/immich-app/immich-server:${version}";
              cmd = [
                "start.sh"
                "microservices"
              ];
              needsDb = true;
              netAlias = "immich-microservices";
            };
            "immich_server" = mkContainer {
              image = "ghcr.io/immich-app/immich-server:${version}";
              cmd = [
                "start.sh"
                "immich"
              ];
              needsDb = true;
              netAlias = "immich-server";
              ports = [ "127.0.0.1:${toString port}:3001/tcp" ];
            };

            "immich_postgres" = mkContainer {
              image = "tensorchord/pgvecto-rs:pg14-v0.1.11@sha256:0335a1a22f8c5dd1b697f14f079934f5152eaaa216c09b61e293be285491f8ee";
              netAlias = "database";
              volumes = [ "pgdata:/var/lib/postgresql/data:rw" ];
            };
            "immich_redis" = mkContainer {
              image = "redis:6.2-alpine@sha256:b6124ab2e45cc332e16398022a411d7e37181f21ff7874835e0180f56a09e82a";
              needSecrets = false;
              netAlias = "redis";
            };

          };
      };
    };

    systemd.services = {
      "docker-immich_machine_learning" = {
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
      "docker-immich_microservices" = {
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
      "docker-immich_postgres" = {
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
      "docker-immich_redis" = {
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
      "docker-immich_server" = {
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
      "docker-network-immich-default" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f immich-default";
        };
        script = ''
          docker network inspect immich-default || docker network create immich-default
        '';
        partOf = [ "docker-compose-immich-root.target" ];
        wantedBy = [ "docker-compose-immich-root.target" ];
      };

      # Volumes
      "docker-volume-model-cache" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect model-cache || docker volume create model-cache
        '';
        partOf = [ "docker-compose-immich-root.target" ];
        wantedBy = [ "docker-compose-immich-root.target" ];
      };
      "docker-volume-pgdata" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect pgdata || docker volume create pgdata
        '';
        partOf = [ "docker-compose-immich-root.target" ];
        wantedBy = [ "docker-compose-immich-root.target" ];
      };
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."docker-compose-immich-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };

    age.secrets."immich/.env".file = ../../secrets/immich/.env.age;
    services.caddy.virtualHosts."${url}" = mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy http://127.0.0.1:${toString port}
        import cloudflare
      '';
    };
  };
}
