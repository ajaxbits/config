{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkIf mkOverride;
  inherit (builtins) toFile toString;
  cfg = config.components.networking.unifi;

  version = "8.2.93";

  dbUser = "unifi";
  dbName = "unifi";
  dbPass = "tXYtGYXCk2ohVH"; # MUST be url-encoded
  dbHost = "unifi-db";
  dbPort = 27017;

  configDir = "/data/config/unifi";
  unifiDir = configDir;
  dbDir = "${configDir}/db";

  # TODO: use env vars here to put password in secrets management.
  # https://github.com/linuxserver/docker-unifi-network-application/issues/9#issuecomment-1872274349
  mongoInit = toFile "init-mongo.js" ''
    db.getSiblingDB("unifi").createUser({user: "${dbUser}", pwd: "${dbPass}", roles: [{role: "dbOwner", db: "${dbName}"}]});
    db.getSiblingDB("unifi_stat").createUser({user: "${dbUser}", pwd: "${dbPass}", roles: [{role: "dbOwner", db: "${dbName}_stat"}]});
  '';
in {
  config = mkIf cfg.enable {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers."unifi-db" = {
      image = "docker.io/mongo:4.4";
      ports = ["${toString dbPort}:27017"];
      volumes = [
        "${dbDir}:/data/db:rw"
        "${mongoInit}:/docker-entrypoint-initdb.d/init-mongo.js:ro"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=unifi-db"
        "--network=unifi-default"
      ];
    };
    systemd.services."docker-unifi-db" = {
      serviceConfig.Restart = mkOverride 500 "always";
      after = ["docker-network-unifi-default.service"];
      requires = ["docker-network-unifi-default.service"];
      partOf = ["docker-compose-unifi-root.target"];
      wantedBy = ["docker-compose-unifi-root.target"];
    };

    virtualisation.oci-containers.containers."unifi-network-application" = {
      image = "lscr.io/linuxserver/unifi-network-application:${version}";
      environment = {
        MONGO_HOST = dbHost;
        MONGO_PORT = toString dbPort;
        MONGO_DBNAME = dbName;
        MONGO_USER = dbUser;
        MONGO_PASS = dbPass;
        MEM_LIMIT = "1024";
        MEM_STARTUP = "1024";
        MONGO_AUTHSOURCE = "";
        MONGO_TLS = "";
        TZ = "America/Chicago";
      };
      volumes = ["${unifiDir}:/config:rw"];
      ports = [
        "127.0.0.1:8443:8443/tcp"
        "3478:3478/udp"
        "10001:10001/udp"
        "8080:8080/tcp"
        "8843:8843/tcp"
        "8880:8880/tcp"
        "6789:6789/tcp"
        "5514:5514/udp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=unifi-network-application"
        "--network=unifi-default"
      ];
    };
    systemd.services."docker-unifi-network-application" = {
      serviceConfig.Restart = mkOverride 500 "always";
      after = ["docker-network-unifi-default.service"];
      requires = ["docker-network-unifi-default.service"];
      partOf = ["docker-compose-unifi-root.target"];
      wantedBy = ["docker-compose-unifi-root.target"];
    };

    # Networks
    systemd.services."docker-network-unifi-default" = {
      path = [pkgs.docker];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "${pkgs.docker}/bin/docker network rm -f unifi-default";
      };
      script = ''
        docker network inspect unifi-default || docker network create unifi-default
      '';
      partOf = ["docker-compose-unifi-root.target"];
      wantedBy = ["docker-compose-unifi-root.target"];
    };

    systemd.targets."docker-compose-unifi-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = ["multi-user.target"];
    };

    services.caddy.virtualHosts."https://wifi.ajax.casa" = mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy 127.0.0.1:8443 {
          transport http {
            tls_insecure_skip_verify
          }
        }
        import cloudflare
      '';
    };
  };
}
