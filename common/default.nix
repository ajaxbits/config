{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.agenix.nixosModules.age
    ./git.nix
    ./nix.nix
    ./fish.nix
    ./upgrade-diff.nix
  ];

  config = {
    environment.systemPackages = import ./pkgs.nix pkgs;

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
  };
}
