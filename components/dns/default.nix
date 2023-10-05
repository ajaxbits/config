{
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.components.dns;
in {
  options.components.dns = {
    enable = mkEnableOption "Enable dns";
  };

  config = mkIf cfg.enable {
    services.blocky = {
      enable = true;
      settings = {
        customDNS = {
          mapping = {
            "ajax.casa" = "172.22.0.10";
          };
        };
      };
    };

    networking.networkmanager.insertNameservers = ["127.0.0.1"];
    networking.firewall.allowedUDPPorts = [53];
  };
}
