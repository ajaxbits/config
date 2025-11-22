{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.components.monitoring = {
    enable = mkEnableOption "Enable the monitoring stack.";
    logs.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable logging framework.";
    };
    visualisation.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable visualisation framework.";
    };
  };

  imports = [
    ./grafana.nix
    ./logs
    ./metrics
  ];
}
