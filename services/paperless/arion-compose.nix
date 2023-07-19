{
  project.name = "paperless";
  services = {
    broker.service = {
      container_name = "paperless-broker";
      image = "docker.io/library/redis:7";
      restart = "unless-stopped";
      volumes = ["redisdata:/data"];
    };
    db.service = {
      container_name = "paperless-db";
      image = "docker.io/library/postgres:13";
      restart = "unless-stopped";
      volumes = ["pgdata:/var/lib/postgresql/data"];
      environment = {
        POSTGRES_DB = "paperless";
        POSTGRES_USER = "paperless";
        POSTGRES_PASSWORD = "paperless";
      };
    };
    webserver.service = {
      container_name = "paperless";
      image = "ghcr.io/paperless-ngx/paperless-ngx:1.16.5";
      restart = "unless-stopped";
      depends_on = [
        "db"
        "broker"
        "gotenberg"
        "tika"
      ];
      ports = ["8000:8000"];
      healthcheck = {
        test = ["CMD" "curl" "-fs" "-S" "--max-time" "2" "http://localhost:8000"];
        interval = "30s";
        timeout = "10s";
        retries = 5;
      };
      volumes = [
        "data:/usr/src/paperless/data"
        "media:/usr/src/paperless/media"
        "/paperless/export:/usr/src/paperless/export"
        "/paperless/consume:/usr/src/paperless/consume"
      ];
      environment = {
        PAPERLESS_TIME_ZONE = "America/Chicago";
        PAPERLESS_REDIS = "redis://paperless-broker:6379";
        PAPERLESS_DBHOST = "db";
        PAPERLESS_TIKA_ENABLED = "1";
        PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://paperless-gotenberg:3000";
        PAPERLESS_TIKA_ENDPOINT = "http://paperless-tika:9998";
      };
    };
    gotenberg.service = {
      container_name = "paperless-gotenberg";
      image = "docker.io/gotenberg/gotenberg:7.8";
      restart = "unless-stopped";
      command = [
        "gotenberg"
        "--chromium-disable-javascript=true"
      ];
    };
    tika.service = {
      container_name = "paperless-tika";
      image = "ghcr.io/paperless-ngx/tika:2.5.0-minimal";
      restart = "unless-stopped";
    };
  };
  docker-compose.raw.volumes = {
    data = {};
    media = {};
    pgdata = {};
    redisdata = {};
  };
}
