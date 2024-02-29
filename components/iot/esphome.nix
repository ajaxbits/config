{
  config,
  lib,
  pkgsUnstable,
  ...
}: let
  inherit
    (lib)
    mkIf
    optionalString
    ;

  cfg = config.components.iot.esphome;
in {
  config = mkIf cfg.enable {
    services.esphome = {
      package = pkgsUnstable.esphome;
      address = "127.0.0.1";
      port = 3334;
    };

    services.caddy.virtualHosts."https://esphome.ajax.casa".extraConfig = optionalString config.components.caddy.enable ''
      reverse_proxy http://${config.services.esphome.address}:${toString config.services.esphome.port}
      import cloudflare
    '';
  };
}
