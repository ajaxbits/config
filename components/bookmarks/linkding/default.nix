{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf optionalString;
  cfg = config.components.bookmarks;
  cfgCaddy = config.components.caddy;

  url = "https://links.${config.networking.domain}";
in {
  options.components.bookmarks = {
    enable = mkEnableOption "Enable bookmark management.";
  };

  config = let
    port = 9923;
  in
    mkIf cfg.enable {
      imports = [
        (import ./compose.nix {
          inherit port;
          configDir = "/data/config";
          public = !cfgCaddy.enable;
        })
      ];
      services.caddy.virtualHosts.${url}.extraConfig = optionalString cfgCaddy.enable ''
        encode gzip zstd
        reverse_proxy http://127.0.0.1:${toString port}
        import cloudflare
      '';
    };
}
