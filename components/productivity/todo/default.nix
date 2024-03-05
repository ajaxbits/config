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
  options.components.productivity.todo = {
    enable = mkEnableOption "Enable todo app.";
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
      encode zstd gzip
      reverse_proxy http://0.0.0.0:${toString config.services.vikunja.port}
      import cloudflare
    '';
  };
}
