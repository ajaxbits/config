{
  inputs,
  pkgs,
  self,
  ...
}: let
  inherit (builtins) pathExists;
  secretsFile = "${self}/secrets/secrets.nix";
in {
  imports = [
    inputs.agenix.nixosModules.age
    ./git.nix
    ./nix.nix
    ./fish.nix
    ./security.nix
    ./ssh.nix
    ./users.nix
    ./upgrade-diff.nix
  ];

  config = {
    environment.systemPackages = import ./pkgs.nix pkgs;

    boot = {
      kernelPackages = pkgs.linuxPackages;
      tmp.cleanOnBoot = true;
      initrd.systemd.enable = true;
    };

    networking.domain = "ajax.casa";

    i18n.defaultLocale = "en_US.UTF-8";

    services.timesyncd.enable = true;
    time.timeZone = "America/Chicago";

    console.keyMap = "us";

    services.fwupd.enable = true;

    assertions = [
      {
        assertion = pathExists secretsFile;
        message = "${secretsFile} does not exist";
      }
    ];
  };
}
