{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib.modules) mkIf;
  cfg = config.components.networking.unifi;
in
{
  config = mkIf (cfg.enable && cfg.monitoring.enable) {
    services = {
      prometheus.exporters.unpoller = {
        enable = true;
        controllers = [
          {
            url = "https://wifi.ajax.casa";
            pass = config.age.secrets."prometheus/unpoller-pass".path;
            user = "unifipoller@example.com";

            verify_ssl = false;
            sites = "all";
            save_ids = true;
            save_events = true;
            save_alarms = true;
            save_dpi = true;
          }
        ];
      };

      victoriametrics.prometheusConfig.scrape_configs =
        let
          inherit (config.services.prometheus.exporters.unpoller) port listenAddress;
        in
        [
          {
            job_name = "unifipoller";
            scrape_interval = "30s";
            static_configs = [
              {
                targets = [ "${listenAddress}:${builtins.toString port}" ];
              }
            ];
          }
        ];
    };

    age.secrets."prometheus/unpoller-pass" = {
      file = "${self}/secrets/prometheus/unpoller-pass.age";
      mode = "440";
      owner = "unpoller-exporter";
      group = "unpoller-exporter";
    };
  };
}
