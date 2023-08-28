{
  agenix,
  config,
  ...
}: let
  repo = "ajaxbits/config";
in {
  imports = [agenix.nixosModules.age];
  nix.extraOptions = "!include ${config.age.secretsDir}/garnix/github-access-token";

  system.autoUpgrade = {
    enable = true;

    flake = "github:${repo}#${config.networking.hostName}";

    dates = "minutely";
    flags = ["--option" "tarball-ttl" "0"];
  };
}
