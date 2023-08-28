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
    enable = true;

    flake = "github:${repo}#${config.networking.hostName}";

    dates = "*-*-* *:5/10:00"; # every 5 minutes
    flags = ["--option" "tarball-ttl" "0"];
  };

  age.secrets."garnix/github-access-token".file = "${self}/secrets/garnix/github-access-token.age";
}
