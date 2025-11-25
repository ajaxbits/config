{ config, ... }:
let
  cfg = config.components.podcasts.vpod;
in
{
  services.vpod = {
    enable = true;
    settings = {
      inherit (cfg) port;
      baseUrl = "https://${cfg.domain}";
      frontend.passwordFile = "/run/agenix/vpod/passwordfile";
      monitoring.victoriaLogsEndpoint = cfg.monitoring.victoriaLogsEndpoint;
    };
  };
  age.secrets."vpod/passwordfile" = {
    file = ../../../secrets/vpod/passwordfile.age;
    mode = "440";
    owner = "vpod";
    group = "vpod";
  };
}
