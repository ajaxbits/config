{
  config,
  lib,
  ...
}: let
  cfg = config.components.monitoring;

  communityString = "Darkened4-Coroner-Pungent";

  oids = {
    ifName = "1.3.6.1.2.1.31.1.1.1.1";
    ifInDiscards = "1.3.6.1.2.1.2.2.1.13";
    ifInErrors = "1.3.6.1.2.1.2.2.1.14";
    ifOutDiscards = "1.3.6.1.2.1.2.2.1.19";
    ifOutErrors = "1.3.6.1.2.1.2.2.1.20";
    ifAdminStatus = "1.3.6.1.2.1.2.2.1.7";
    ifOperStatus = "1.3.6.1.2.1.2.2.1.8";
    ifLastChange = "1.3.6.1.2.1.2.2.1.9";
    hrSystemUptime = "1.3.6.1.2.1.25.1.1";
    hrSystemProcesses = "1.3.6.1.2.1.25.1.6";
    hrSystemMaxProcesses = "1.3.6.1.2.1.25.1.7";
    hrMemorySize = "1.3.6.1.2.1.25.2.2";
    hrStorageSize = "1.3.6.1.2.1.25.2.3.1.5";
    hrStorageUsed = "1.3.6.1.2.1.25.2.3.1.6";
    hrProcessorLoad = "1.3.6.1.2.1.25.3.3.1.2";
    ifHCOutOctets = "1.3.6.1.2.1.31.1.1.1.10";
    ifHCInOctets = "1.3.6.1.2.1.31.1.1.1.6";
    tcpMaxConn = "1.3.6.1.2.1.6.4";
    tcpActiveOpens = "1.3.6.1.2.1.6.5";
    tcpPassiveOpens = "1.3.6.1.2.1.6.6";
    tcpEstabResets = "1.3.6.1.2.1.6.8";
    tcpCurrEstab = "1.3.6.1.2.1.6.9";
    ssCpuRawIdle = "1.3.6.1.4.1.2021.11.53";
    memTotalReal = "1.3.6.1.4.1.2021.4.5";
    memAvailReal = "1.3.6.1.4.1.2021.4.6";
  };

  createMetric = {
    name,
    help,
    type,
    indexes ? [],
    lookups ? [],
    ifNameIndexAndLookup ? false,
  }: let
    condition = ifNameIndexAndLookup || lib.strings.hasPrefix "if" name;
  in {
    inherit type help;
    name = "erx_${name}";
    oid = oids.${name};
    indexes =
      indexes
      ++ lib.optional condition {
        labelname = "ifName";
        type = "gauge";
      };
    lookups =
      lookups
      ++ lib.optional condition {
        labels = ["ifName"];
        labelname = "ifName";
        oid = oids.ifName;
        type = "DisplayString";
      };
  };
in {
  config.services.prometheus = lib.mkIf (cfg.enable && cfg.networking.enable) {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "snmp";
        scrape_interval = "5s";
        static_configs = [{targets = ["172.22.0.1"];}];
        metrics_path = "/snmp";
        params.module = ["edgerouterx"];
        relabel_configs = [
          {
            source_labels = ["__address__"];
            target_label = "__param_target";
          }
          {
            source_labels = ["__param_target"];
            target_label = "instance";
          }
          {
            target_label = "__address__";
            replacement = "127.0.0.1:9116";
          }
        ];
      }
    ];

    # exporters.snmp = {
    #   enable = true;
    #   configuration.edgerouterx = {
    #     walk = builtins.map (name: oids.${name}) [
    #       "hrProcessorLoad"
    #       "hrStorageSize"
    #       "hrStorageUsed"
    #       "ifAdminStatus"
    #       "ifHCInOctets"
    #       "ifHCOutOctets"
    #       "ifInDiscards"
    #       "ifInErrors"
    #       "ifLastChange"
    #       "ifName"
    #       "ifOperStatus"
    #       "ifOutDiscards"
    #       "ifOutErrors"
    #     ];
    #
    #     get = builtins.map (name: "${oids.${name}}.0") [
    #       "hrMemorySize"
    #       "hrSystemMaxProcesses"
    #       "hrSystemProcesses"
    #       "hrSystemUptime"
    #       "memAvailReal"
    #       "memTotalReal"
    #       "ssCpuRawIdle"
    #       "tcpActiveOpens"
    #       "tcpCurrEstab"
    #       "tcpEstabResets"
    #       "tcpMaxConn"
    #       "tcpPassiveOpens"
    #     ];
    #
    #     metrics = builtins.map createMetric [
    #       {
    #         name = "ifInDiscards";
    #         type = "counter";
    #         help = "The number of inbound packets which were chosen to be discarded even though no errors had been detected to prevent their being deliverable to a higher-layer protocol.";
    #       }
    #       {
    #         name = "ifInErrors";
    #         type = "counter";
    #         help = "For packet-oriented interfaces, the number of inbound packets that contained errors preventing them from being deliverable to a higher-layer protocol.";
    #       }
    #       {
    #         name = "ifOutDiscards";
    #         type = "counter";
    #         help = "The number of outbound packets which were chosen to be discarded even though no errors had been detected to prevent their being transmitted.";
    #       }
    #       {
    #         name = "ifOutErrors";
    #         type = "counter";
    #         help = "For packet-oriented interfaces, the number of outbound packets that could not be transmitted because of errors.";
    #       }
    #       {
    #         name = "ifAdminStatus";
    #         type = "gauge";
    #         help = "The desired state of the interface.";
    #       }
    #       {
    #         name = "ifOperStatus";
    #         type = "gauge";
    #         help = "The current operational state of the interface.";
    #       }
    #       {
    #         name = "ifLastChange";
    #         type = "gauge";
    #         help = "The value of sysUpTime at the time the interface entered its current operational state.";
    #       }
    #       {
    #         name = "hrSystemUptime";
    #         type = "gauge";
    #         help = "The amount of time since this host was last initialized.";
    #       }
    #       {
    #         name = "hrSystemProcesses";
    #         type = "gauge";
    #         help = "The number of process contexts currently loaded or running on this system.";
    #       }
    #       {
    #         name = "hrSystemMaxProcesses";
    #         type = "gauge";
    #         help = "The maximum number of process contexts this system can support.";
    #       }
    #       {
    #         name = "hrMemorySize";
    #         type = "gauge";
    #         help = "The amount of physical read-write main memory, typically RAM, contained by the host.";
    #       }
    #       {
    #         name = "hrStorageSize";
    #         type = "gauge";
    #         help = "The size of the storage represented by this entry, in units of hrStorageAllocationUnits.";
    #         indexes = [
    #           {
    #             labelname = "hrStorageIndex";
    #             type = "gauge";
    #           }
    #         ];
    #       }
    #       {
    #         name = "hrStorageUsed";
    #         type = "gauge";
    #         help = "The amount of the storage represented by this entry that is allocated, in units of hrStorageAllocationUnits.";
    #         indexes = [
    #           {
    #             labelname = "hrStorageIndex";
    #             type = "gauge";
    #           }
    #         ];
    #       }
    #       {
    #         name = "hrProcessorLoad";
    #         type = "gauge";
    #         help = "The average, over the last minute, of the percentage of time that this processor was not idle.";
    #         indexes = [
    #           {
    #             labelname = "hrDeviceIndex";
    #             type = "gauge";
    #           }
    #         ];
    #       }
    #       {
    #         name = "ifHCOutOctets";
    #         type = "counter";
    #         help = "The total number of octets transmitted out of the interface, including framing characters.";
    #       }
    #       {
    #         name = "ifHCInOctets";
    #         type = "counter";
    #         help = "The total number of octets received on the interface, including framing characters.";
    #       }
    #       {
    #         name = "tcpMaxConn";
    #         type = "gauge";
    #         help = "The limit on the total number of TCP connections the entity can support.";
    #       }
    #       {
    #         name = "tcpActiveOpens";
    #         type = "counter";
    #         help = "The number of times TCP connections have made a direct transition to the SYN-SENT state from the CLOSED state.";
    #       }
    #       {
    #         name = "tcpPassiveOpens";
    #         type = "counter";
    #         help = "The number of times TCP connections have made a direct transition to the SYN-RCVD state from the LISTEN state.";
    #       }
    #       {
    #         name = "tcpEstabResets";
    #         type = "counter";
    #         help = "The number of times TCP connections have made a direct transition to the CLOSED state from either the ESTABLISHED state or the CLOSE-WAIT state.";
    #       }
    #       {
    #         name = "tcpCurrEstab";
    #         type = "gauge";
    #         help = "The number of TCP connections for which the current state is either ESTABLISHED or CLOSE-WAIT.";
    #       }
    #       {
    #         name = "ssCpuRawIdle";
    #         type = "counter";
    #         help = "The number of 'ticks' (typically 1/100s) spent idle.";
    #       }
    #       {
    #         name = "memTotalReal";
    #         type = "gauge";
    #         help = "The total amount of real/physical memory installed on this host.";
    #       }
    #       {
    #         name = "memAvailReal";
    #         type = "gauge";
    #         help = "The amount of real/physical memory currently unused or available.";
    #       }
    #     ];
    #
    #     auth.community = communityString;
    #   };
    # };
  };
}
