{
  config,
  lib,
  ...
}:
let
  cfg = config.components.cd;
in
{
  options.components.cd.enable = lib.mkEnableOption "Enable CI/CD through Garnix";
  options.components.cd.repo = lib.mkOption {
    type = lib.types.str;
    description = "Repo that is used to pull config from";
    default = "ajaxbits/config";
  };

  config = lib.mkIf cfg.enable {
    nix.extraOptions = "!include ${config.age.secretsDir}/garnix/github-access-token";

    system.autoUpgrade = {
      enable = true;

      flake = "github:${cfg.repo}#${config.networking.hostName}";

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

    age.secrets."garnix/github-access-token".file = ../../secrets/garnix/github-access-token.age;
  };
}
