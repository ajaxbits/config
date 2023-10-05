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

        blocking = {
          blackLists = {
            minimal = [
              "https://big.oisd.nl/regex"
            ];
          };
          clientGroupsBlock.default = [
            "minimal"
          ];
          blockTTL = "1m";
          startStrategy = "fast";
        };

        prometheus = lib.mkIf config.components.monitoring.enable {
          enable = true;
          path = "localhost:${builtins.toString config.services.prometheus.port}/metrics";
        };

        #   https://github.com/0xERR0R/blocky/issues/287
        caching.cacheTimeNegative = "1m";
      };
    };

    networking.networkmanager.insertNameservers = ["127.0.0.1"];
    networking.firewall.allowedUDPPorts = [53];
  };
}
