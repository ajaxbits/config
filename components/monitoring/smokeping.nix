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
    services.smokeping.targetConfig = ''
    
      probe = FPing
      menu = Top
      title = Network Latency Grapher
      remark = Welcome to the SmokePing website of Arch User. \
               Here you will learn all about the latency of our network.

      + targets
      menu = Targets
      title = Targets

      ++ CloudflareDNS1
       
      menu = Cloudflare DNS
      title = Cloudflare DNS server 1.1.1.1
      host = 1.1.1.1
      
      ++ CloudflareDNS2
       
      menu = Cloudflare DNS
      title = Cloudflare DNS server 1.0.0.1
      host = 1.0.0.1

      ++ GoogleDNS

      menu = Google DNS
      title = Google DNS server
      host = 8.8.8.8

      ++ MultiHost

      menu = Multihost example
      title = CloudflareDNS and Google DNS
      host = /targets/CloudflareDNS1 /targets/CloudflareDNS2 /targets/GoogleDNS
      
    '';
    
    services.prometheus.exporters.smokeping = {
      enable = true;
    }; 
  };
}
