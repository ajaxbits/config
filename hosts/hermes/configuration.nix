{pkgs, user, ...}: {
  imports = [
    ./tlp.nix
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = true;

  networking.hostName = "hermes";
  networking.hostId = "b7d14532";
  networking.networkmanager.enable = true;
  systemd.services.NetworkManager-wait-online.enable = false; #TODO this is a bugfix, evaluate later

  networking.firewall.enable = false;

  services.nextdns = {
    enable = true;
    arguments = [
      "-config"
      "b698e3"
    ];
  };
  components = {
    desktop = {
      enable = true;
      browser.firefox.enable = true;
      terminal.wezterm.enable = true;
      wm.sway.enable = true;
    };
    cd.enable = true;
    tailscale = {
      enable = true;
      initialAuthKey = "tskey-auth-k5VoMt2CNTRL-C4sAH3gN4u596AcSmBdwz5ZDXZnX1vHM";
      tags = ["ajax" "nixos"];
      advertiseExitNode = false;
    };
  };

  home-manager.users.${user} = {...}: {
    imports = [./home.nix];
  };

  musnix = {
    enable = true;
  };
  services.pipewire.jack.enable = true;
  environment.systemPackages = [pkgs.zrythm];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
