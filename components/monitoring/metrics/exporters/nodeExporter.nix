{ config, lib, ... }:
let
  inherit (lib) mkIf;
  inherit (builtins) elem;

  monCfg = config.components.monitoring;
  cfg = config.components.monitoring.metrics;
  textfileDir = "/var/lib/prometheus-node-exporter-text-files";
in
{
  config = mkIf (monCfg.enable && cfg.enable && elem "nodeExporter" cfg.exporters) {
    services = {
      prometheus.exporters.node = {
        enable = true;
        enabledCollectors = [
          "ethtool"
          "interrupts"
          "processes"
          "softirqs"
          "systemd"
          "textfile"
          "tcpstat"
        ];
        extraFlags = [ "--collector.textfile.directory=${textfileDir}" ];
        port = 9002;
      };

      victoriametrics.prometheusConfig.scrape_configs = [
        {
          job_name = "node-exporter-${config.networking.hostName}";
          scrape_interval = "30s";
          metrics_path = "/metrics";
          static_configs = [
            {
              targets = [ "localhost:9002" ];
              labels.type = "node";
              labels.host = config.networking.hostName;
            }
          ];
        }
      ];
    };

    system.activationScripts.nodeExporterSystemVersion.text = ''
      generation=$(readlink /nix/var/nix/profiles/system || true)
      if [[ $generation =~ ^system-([0-9]+)-link$ ]]; then
        install -d -m 0755 ${textfileDir}
        printf 'system_version %s\n' "''${BASH_REMATCH[1]}" > ${textfileDir}/system-version.prom.next
        mv -f ${textfileDir}/system-version.prom.next ${textfileDir}/system-version.prom
      else
        rm -f ${textfileDir}/system-version.prom
        echo "Cannot read NixOS system profile generation: $generation" >&2
      fi
    '';
  };
}
