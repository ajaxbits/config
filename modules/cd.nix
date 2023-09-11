{
  agenix,
  config,
  self,
  ...
}: let
  repo = "ajaxbits/config";
in {
  imports = [agenix.nixosModules.age];
  nix.extraOptions = "!include ${config.age.secretsDir}/garnix/github-access-token";

  system.autoUpgrade = {
    enable = false;

    flake = "github:${repo}#${config.networking.hostName}";

    dates = "minutely";
    flags = ["--option" "tarball-ttl" "0"];
  };

  age.secrets."garnix/github-access-token".file = "${self}/secrets/garnix/github-access-token.age";
}
