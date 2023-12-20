{
  config,
  lib,
  pkgsLatest,
  ...
}: let
  inherit
    (lib)
    mkForce
    mkIf
    optionalAttrs
    optionalString
    ;

  cfg = config.components.iot.esphome;
in {
  config = mkIf cfg.enable {
    services.esphome = {
      enable = true;
      package = pkgsLatest.esphome;
      enableUnixSocket = config.components.caddy.enable;
    };

    systemd.services.esphome.serviceConfig =
      {
        ProtectHostname = mkForce false;
        ProtectKernelLogs = mkForce false;
        ProtectKernelTunables = mkForce false;
        ProcSubset = "all";
      }
      // optionalAttrs config.components.caddy.enable {
        RuntimeDirectoryMode = mkForce "0755";
      };

    services.caddy.virtualHosts."https://esphome.ajax.casa".extraConfig = optionalString config.components.caddy.enable ''
      reverse_proxy unix//run/esphome/esphome.sock
      import cloudflare
    '';
  };
}
