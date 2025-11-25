{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;
in
{
  options.components.podcasts.vpod = {
    enable = mkEnableOption "Enable vpod.";
    domain = mkOption {
      type = types.str;
      description = "The domain where all podcasts are hosted at.";
      default = "podcasts.ajax.lol";
    };
    port = mkOption {
      type = types.port;
      default = 4119;
    };
    monitoring.victoriaLogsEndpoint = mkOption {
      type = types.str;
      description = "where to send logs to";
      default = "http://172.22.0.10:9428";
    };
    frontend.passwordFile = mkOption {
      type = types.str;
      description = "The file where the service can find the frontend pass";
    };
    vm = {
      ip = mkOption {
        type = types.str;
        default = "172.22.2.51";
      };
      gatewayCIDR = mkOption {
        type = types.str;
        default = "172.22.0.1/15";
      };
    };
  };
}
