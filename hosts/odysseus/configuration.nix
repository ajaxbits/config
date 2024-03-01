{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  networking.hostName = "odysseus";
  networking.hostId = "b7d14532";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false; #TODO this is a bugfix, evaluate later

  networking.firewall.enable = false;

  components = {
    desktop = {
      wm.sway.enable = true;
    };
    filesystems = {
      bcachefs.enable = false;
      zfs.enable = true;
    };
    tailscale = {
      enable = true;
      initialAuthKey = "tskey-auth-kCJEH64CNTRL-KDvHnxkzYEQEwhQC9v2L8QgQ8Lu8HcYnN";
      tags = ["ajax" "nixos"];
      advertiseExitNode = false;
    };
  };

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bkup";
  home-manager.users.admin = {...}: {
    imports = [./home.nix];

    programs.home-manager.enable = true;
    home.enableNixpkgsReleaseCheck = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
