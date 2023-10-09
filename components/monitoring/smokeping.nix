{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config = lib.mkIf cfg.enable {
    services.smokeping = {
      enable = true;
      probeConfig = ''
        + FPing
        binary = ${config.security.wrapperDir}/fping
        + DNS
        binary = ${pkgs.dnsutils}/bin/dig
      '';
      targetConfig = ''
        probe = FPing
        menu = Top
        title = Network Latency Grapher
        remark = Smokeping for ajax's network

        + DNSPings
        menu = DNS Pings
        title = DNS Pings

        ++ CloudflareDNS1
        menu = Cloudflare DNS 1
        title = Cloudflare DNS 1.1.1.1
        host = 1.1.1.1

        ++ CloudflareDNS2
        menu = Cloudflare DNS 1
        title = Cloudflare DNS 1.0.0.1
        host = 1.0.0.1

        ++ Quad9
        menu = Quad9 DNS
        title = Quad9 DNS 9.9.9.9
        host = 9.9.9.9

        ++ Google
        menu = Google DNS
        title = Google DNS 8.8.8.8
        host = 8.8.8.8

        ++ NextDNS1
        menu = NextDNS 1
        title = NextDNS 45.90.28.204
        host = 45.90.28.204

        ++ NextDNS2
        menu = NextDNS 2
        title = NextDNS 45.90.30.204
        host = 45.90.30.204

        ++ Cloudflare
        menu = All Cloudflare DNS pings
        title = All Cloudflare DNS pings
        host = /DNSPings/CloudflareDNS1 /DNSPings/CloudflareDNS2

        ++ NextDNS
        menu = All NextDNS pings
        title = All NextDNS pings
        host = /DNSPings/NextDNS1 /DNSPings/NextDNS2

        ++ AllPings
        menu = All DNS pings
        title = All DNS pings
        host = /DNSPings/CloudflareDNS1 /DNSPings/CloudflareDNS2 /DNSPings/Quad9 /DNSPings/Google /DNSPings/NextDNS1 /DNSPings/NextDNS2


        + DNSProbes
        menu = DNS Probes
        title = DNS Probes
        probe = DNS

        ++ CloudflareDNS1
        menu = Cloudflare DNS 1
        title = Cloudflare DNS 1.1.1.1
        host = 1.1.1.1

        ++ CloudflareDNS2
        menu = Cloudflare DNS 1
        title = Cloudflare DNS 1.0.0.1
        host = 1.0.0.1

        ++ Quad9
        menu = Quad9 DNS
        title = Quad9 DNS 9.9.9.9
        host = 9.9.9.9

        ++ Google
        menu = Google DNS
        title = Google DNS 8.8.8.8
        host = 8.8.8.8

        ++ NextDNS1
        menu = NextDNS 1
        title = NextDNS 45.90.28.204
        host = 45.90.28.204

        ++ NextDNS2
        menu = NextDNS 2
        title = NextDNS 45.90.30.204
        host = 45.90.30.204

        ++ Cloudflare
        menu = All Cloudflare DNS probes
        title = All Cloudflare DNS probes
        host = /DNSProbes/CloudflareDNS1 /DNSProbes/CloudflareDNS2

        ++ NextDNS
        menu = All NextDNS probes
        title = All NextDNS probes
        host = /DNSProbes/NextDNS1 /DNSProbes/NextDNS2

        ++ AllProbes
        menu = All DNS probes
        title = All DNS probes
        host = /DNSProbes/CloudflareDNS1 /DNSProbes/CloudflareDNS2 /DNSProbes/Quad9 /DNSProbes/Google /DNSProbes/NextDNS1 /DNSProbes/NextDNS2
      '';
    };

    services.smokeping.webService = !config.components.caddy.enable;
    services.fcgiwrap.enable = config.components.caddy.enable;
    services.caddy.virtualHosts."http://smokeping.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = let
        # taken from defn: https://github.com/NixOS/nixpkgs/blob/5a237aecb57296f67276ac9ab296a41c23981f56/nixos/modules/services/networking/smokeping.nix#L7
        smokepingHome = "/var/lib/smokeping";
      in ''
        handle /js/* {
          root * ${smokepingHome}/
          file_server
        }
        handle /css/* {
          root * ${smokepingHome}/
          file_server
        }
        handle /imgcache/* {
          root * ${smokepingHome}/
          file_server
        }
        handle /images/* {
          root * ${smokepingHome}/
          file_server
        }

        handle {
          root * ${smokepingHome}/
          reverse_proxy ${config.services.fcgiwrap.socketType}/${config.services.fcgiwrap.socketAddress} {
            transport fastcgi {
              env SCRIPT_FILENAME ${smokepingHome}/smokeping.fcgi
              split ""
            }
          }
        }
      '';
    };
  };
}
