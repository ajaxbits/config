{
  config,
  lib,
  ...
}: let
  cfg.enable = config.components.monitoring.enable && config.components.monitoring.networking.enable;
in {
  config = lib.mkIf cfg.enable {
    services.smokeping.enable = true;
    services.smokeping.host = "0.0.0.0";
    services.smokeping.targetConfig = ''
      probe = FPing

      menu = Top
      title = Network Latency Grapher

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
    '';
  };
}
