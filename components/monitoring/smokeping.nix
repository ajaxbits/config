{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config = lib.mkIf cfg.enable {
    services.smokeping.enable = true;
    services.smokeping.host = "0.0.0.0";
  };
}
