{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionalString;
  cfg = config.components.productivity.todo;
  cfgCaddy = config.components.caddy;

  url = "https://todo.${config.networking.domain}";
in {
  options.components.bookmarks = {
    enable = mkEnableOption "Enable bookmark management.";
  };

  config = mkIf cfg.enable {
    services.vikunja = {
      enable = true;
      frontendScheme =
        if cfgCaddy.enable
        then "https"
        else "http";
      frontendHostname =
        if cfgCaddy.enable
        then url
        else "localhost:${toString config.services.vikunja.port}";
    };
    services.caddy.virtualHosts.${url}.extraConfig = optionalString cfgCaddy.enable ''
      @paths {
        path /api/* /.well-known/* /dav/*
      }

      handle @paths {
        reverse_proxy 127.0.0.1:${toString config.services.vikunja.port}
      }

      handle {
        encode zstd gzip
        root * ${config.services.vikunja.package-frontend}
        try_files {path} index.html
        file_server
      }
    '';
  };
}
