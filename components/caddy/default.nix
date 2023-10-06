{
  config,
  lib,
  ...
}: let
  cfg = config.components.caddy;
in {
  options.components.caddy = {
    enable = lib.mkEnableOption "caddy";
  };

  config = lib.mkIf cfg.enable {
    services.caddy.enable = true;
  };
}
