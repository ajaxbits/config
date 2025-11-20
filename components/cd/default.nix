{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.components.cd;

  # thanks to yomaq the GOAT for this tech
  # https://github.com/yomaq/nix-config/blob/ca913788f2c3f54475e2c8e6d9076e8f5b68b6a8/modules/hosts/autoUpgradeNix/nixos.nix#L19
  isClean = inputs.self ? rev;
in
{
  options.components.cd.enable = lib.mkEnableOption "Enable CI/CD through Garnix";
  options.components.cd.flake = lib.mkOption {
    type = lib.types.str;
    description = "Flake that is used to pull config from";
    default = "github:ajaxbits/config#${config.networking.hostName}";
  };

  config = lib.mkIf cfg.enable {
    nix.extraOptions = "!include ${config.age.secretsDir}/garnix/github-access-token";

    system.autoUpgrade = {
      enable = isClean;

      inherit (cfg) flake;

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
