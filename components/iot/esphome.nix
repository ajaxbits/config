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
  version = "2023.12.5";
in {
  config = mkIf cfg.enable {
    virtualisation.oci-containers.containers.esphome = {
      image = "ghcr.io/esphome/esphome:${version}";
      user = "root";
      volumes = ["/etc/localtime:/etc/localtime:ro" "/data/config/esphome:/config"];
      extraOptions = ["--network=host"];
    };

    users.users = {
      esphome = {
        isSystemUser = true;
        group = "esphome";
        extraGroups = ["configoperators"];
      };
    };
    users.groups = {
      esphome = {};
      configoperators = {};
    };
    
    services.caddy.virtualHosts."https://esphome.ajax.casa".extraConfig = optionalString config.components.caddy.enable ''
      reverse_proxy http://0.0.0.0:6052
      import cloudflare
    '';
  };
}