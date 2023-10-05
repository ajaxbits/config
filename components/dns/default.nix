{
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.components.dns;
in {
  options.components.dns = {
    enable = mkEnableOption "Enable dns";
  };

  config = mkIf cfg.enable {
    services.blocky = {
      enable = true;

      settings = {
        startStrategy = "fast";
        clientLookup.upstream = "172.22.0.1";
        conditional.mapping."." = "172.22.0.1";

        upstream = {
          default = [
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        customDNS = {
          mapping = {
            "ajax.casa" = "172.22.0.10";
          };
        };

        #   https://github.com/0xERR0R/blocky/issues/287
        caching.cacheTimeNegative = "1m";
      };
    };

    networking.networkmanager.insertNameservers = ["127.0.0.1"];
    networking.firewall.allowedUDPPorts = [53];
  };
}
