{
  self,
  config,
  lib,
  ...
}: let
  cfg = config.components.monitoring;
in {
  options.components.monitoring = {
    enable = lib.mkEnableOption "Enable the monitoring stack.";
    uptime.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable uptime monitoring stack.";
    };
    visualisation.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable visualisation framework.";
    };
    logging.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable logging framework.";
    };
    networking.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable network monitoring.";
    };
  };

  imports = [
    ./grafana.nix
    ./loki.nix
    ./prometheus.nix
    ./smokeping.nix
    ./uptimekuma.nix
  ];
}
