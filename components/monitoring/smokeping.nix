{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config = lib.mkIf cfg.enable {
    services.smokeping.enable = true;
    services.smokeping.host = "0.0.0.0";
    services.smokeping.probeconfig = ''
      + FPing
      binary = ${config.security.wrapperDir}/fping
      + DNS
      binary = ${pkgs.dnsutils}/bin/dig
    '';
    services.smokeping.targetConfig = ''
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
      host = /targets/CloudflareDNS1 /targets/CloudflareDNS2

      ++ NextDNS
      menu = All NextDNS pings
      title = All NextDNS pings
      host = /targets/NextDNS1 /targets/NextDNS2

      ++ AllPings
      menu = All DNS pings
      title = All DNS pings
      host = /targets/CloudflareDNS1 /targets/CloudflareDNS2 /targets/Quad9 /targets/Google /targets/NextDNS1 /targets/NextDNS2


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
      host = /targets/CloudflareDNS1 /targets/CloudflareDNS2

      ++ NextDNS
      menu = All NextDNS probes
      title = All NextDNS probes
      host = /targets/NextDNS1 /targets/NextDNS2

      ++ AllProbes
      menu = All DNS probes
      title = All DNS probes
      host = /targets/CloudflareDNS1 /targets/CloudflareDNS2 /targets/Quad9 /targets/Google /targets/NextDNS1 /targets/NextDNS2
    '';
  };
}
