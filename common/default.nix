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
    ./users.nix
    ./upgrade-diff.nix
  ];

  config = {
    environment.systemPackages = import ./pkgs.nix pkgs;

    boot.kernelPackages = pkgs.linuxPackages;
    boot.tmp.cleanOnBoot = true;

    networking.domain = "ajax.casa";

    i18n.defaultLocale = "en_US.UTF-8";

    services.timesyncd.enable = true;
    time.timeZone = "America/Chicago";

    console.keyMap = "us";

    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
      };
    };
    services.fwupd.enable = true;

    programs.ssh.startAgent = true;
    programs.mosh.enable = true;

    assertions = [
      {
        assertion = pathExists secretsFile;
        message = "${secretsFile} does not exist";
      }
    ];
  };
}
