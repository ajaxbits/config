{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.uptime.enable;
in {
  config = lib.mkIf cfg.enable {
    services.uptime-kuma = {
      enable = true;
      appriseSupport = true;
      settings.HOST = "0.0.0.0";
      settings.PORT = "4000";
    };
  };
}
