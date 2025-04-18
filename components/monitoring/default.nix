{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.components.monitoring = {
    enable = mkEnableOption "Enable the monitoring stack.";
    uptime.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable uptime monitoring stack.";
    };
    visualisation.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable visualisation framework.";
    };
    logging.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable logging framework.";
    };
    networking.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable network monitoring.";
    };
    victorialogs.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable victorialogs.";
    };
    victoriametrics.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable victoriametrics.";
    };
  };

  imports = [
    ./grafana.nix
    ./loki.nix
    ./prometheus
    ./smokeping.nix
    ./uptimekuma.nix
    ./victorialogs.nix
    ./victoriametrics.nix
  ];
}
