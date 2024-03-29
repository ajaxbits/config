{
  config,
  lib,
  ...
}: let
  inherit (builtins) toString;
  inherit (lib) mkEnableOption mkIf optionals;

  cfg = config.components.dns;
in {
  options.components.dns = {
    enable = mkEnableOption "Enable dns";
  };

  config = mkIf cfg.enable {
    services.blocky = {
      enable = true;

      settings = {
        ports.dns = 53;
        ports.http = 2019;

        clientLookup.upstream = "172.22.0.1";
        conditional.mapping."." = "172.22.0.1";

        upstream = {
          default = [
            "194.242.2.2"
            "1.1.1.1"
            "9.9.9.9"
          ];
        };

        customDNS = {
          mapping = {
            "ajax.lan" = "172.22.0.10";
          };
        };

        blocking = {
          blackLists = {
            minimal = [
              "https://small.oisd.nl/regex"
            ];
            full = [
              "https://big.oisd.nl/regex"
            ];
          };
          clientGroupsBlock.default = [
            "full"
          ];
          blockTTL = "1m";
          startStrategy = "fast";
        };

        prometheus = lib.mkIf config.components.monitoring.enable {
          enable = true;
          path = "/metrics";
        };

        #   https://github.com/0xERR0R/blocky/issues/287
        caching.cacheTimeNegative = "1m";
      };
    };

    services.prometheus.scrapeConfigs = optionals config.components.monitoring.enable [
      {
        job_name = "blocky";
        static_configs = [
          {
            targets = ["127.0.0.1:${toString config.services.blocky.settings.ports.http}"];
          }
        ];
      }
    ];

    services.grafana.settings.panels = lib.mkIf config.components.monitoring.enable {
      disable_sanitize_html = true;
    };

    networking.networkmanager.insertNameservers = ["127.0.0.1"];
    networking.firewall.allowedUDPPorts = [53];
  };
}
