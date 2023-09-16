{
  config,
  self,
  ...
}: {
  imports = [
    ./uptimekuma.nix
    ./grafana.nix
    ./loki.nix
    (
      if config.networking.hostName != "patroclus"
      then
        import ./prometheus.nix {
          inherit config;
          unpollerPass = config.age.secrets."prometheus/unpoller-pass".path;
        }
      else {}
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
