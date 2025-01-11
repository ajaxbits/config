{
  lib,
  config,
  pkgsUnstable,
  ...
}:
let
  inherit (lib) mkIf optionalString;

  cfg = config.components.mediacenter.invidious;
  caddyEnabled = config.components.caddy.enable;
in
{
  config = mkIf cfg.enable {
    services.invidious = {
      enable = true;
      package = pkgsUnstable.invidious;

      domain = optionalString caddyEnabled "yt.ajax.casa";
      address = if caddyEnabled then "127.0.0.1" else "0.0.0.0";
      port = 6666;

      settings = {
        db.user = "invidious";
        https_only = caddyEnabled;
        external_port = optionalString caddyEnabled 443;
        popular_enabled = false;
      };
    };

    services.caddy.virtualHosts = mkIf caddyEnabled (
      let
        inherit (config.services.invidious) address domain port;
      in
      {
        "https://${domain}".extraConfig = ''
          encode gzip zstd
          reverse_proxy http://${address}:${toString port}
          import cloudflare
        '';
      }
    );
  };
}
