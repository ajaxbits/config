{ guestHostName, ... }:
{
  # TODO: make this into a module that works well

  # guest config
  microvm.vms.${guestHostName}.config = {
    networking.firewall.allowedTCPPorts = [ 9002 ];
    services.prometheus.exporters.node = {
      enable = true;
      enabledCollectors = [
        "ethtool"
        "interrupts"
        "processes"
        "softirqs"
        "systemd"
        "tcpstat"
      ];
      port = 9002;
    };
  };

  # host config
  services.victoriametrics.prometheusConfig.scrape_configs = [
    {
      job_name = "node-exporter-${guestHostName}";
      scrape_interval = "30s";
      metrics_path = "/metrics";
      static_configs = [
        {
          targets = [ "172.22.2.51:9002" ]; # TODO: factor
          labels.type = "node";
          labels.host = guestHostName;
        }
      ];
    }
  ];

}
