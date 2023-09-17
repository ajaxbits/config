{
  self,
  config,
  pkgs,
  ...
}: {
    imports = [
      ./uptimekuma.nix
      ./grafana.nix
      ./loki.nix
      ./smokeping.nix
      (
        import ./prometheus.nix {
          inherit config;
          unpollerPass = config.age.secrets."prometheus/unpoller-pass".path;
        }
      )
    ];

    age.secrets = {
      "prometheus/unpoller-pass" = {
        file = "${self}/secrets/prometheus/unpoller-pass.age";
        mode = "440";
        owner = "unpoller-exporter";
        group = "unpoller-exporter";
      };
    };
}
