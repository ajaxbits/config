{
  config,
  self,
  lib,
  ...
}: let
  repo = "ajaxbits/config";
  cfg = config.components.cd;
in {
  options.components.cd.enable = lib.mkEnableOption "Enable CI/CD through Garnix";

  config = lib.mkIf cfg.enable {
    nix.extraOptions = "!include ${config.age.secretsDir}/garnix/github-access-token";

    system.autoUpgrade = {
      enable = true;

      flake = "github:${repo}/authentik#${config.networking.hostName}";

      dates = "minutely";
      flags = [
        "--option"
        "accept-flake-config"
        "true"

        # required if using a small `dates` value
        "--option"
        "tarball-ttl"
        "0"
      ];

      allowReboot = true;
      rebootWindow = {
        lower = "01:00";
        upper = "05:00";
      };
    };

    age.secrets."garnix/github-access-token".file = "${self}/secrets/garnix/github-access-token.age";
  };
}
