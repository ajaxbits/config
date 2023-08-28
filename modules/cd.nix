{
  agenix,
  config,
  self,
  ...
}: let
  repo = "ajaxbits/config";
in {
  imports = [agenix.nixosModules.age];
  nix.extraOptions = "!include ${config.age.secrets."garnix/github-access-token".path}";

  system.autoUpgrade = {
    enable = true;

    flake = "github:${repo}#${config.networking.hostName}";

    dates = "minutely";
    flags = ["--option" "tarball-ttl" "0"];
  };

  age.secrets."garnix/github-access-token".file = "${self}/secrets/forgejo/postgresql-pass.age";
}
