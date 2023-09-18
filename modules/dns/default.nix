{
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.modules.dns;
in {
  options.modules.dns = {
    enable = mkEnableOption "Enable dns";
  };

  config = mkIf cfg.enable {
    services.coredns = {
      enable = true;
      config = ''
        . {
          # Cloudflare and Quad9
          forward . 1.1.1.1 1.0.0.1 9.9.9.9
          cache
        }

        ajaxbits.xyz {
          log
        }
      '';

      networking.networkmanager.insertNameservers = ["127.0.0.1"];
      networking.firewall.allowedUDPPorts = [53];
    };
  };
}
