{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption;
in
{
  options.components.networking.unifi = {
    enable = mkEnableOption "Enable unifi controller framework.";
    monitoring.enable = mkOption {
      default = true;
      example = false;
      description = "Whether to enable Prometheus metrics for the Unifi Controller.";
      type = lib.types.bool;
    };
  };

  imports = [
    ./unifi
  ];
}
