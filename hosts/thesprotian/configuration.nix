{
  config,
  pkgs,
  lib,
  ...
}: let
  fetchKeysList = username: (lib.remove "" (lib.splitString "\n" (builtins.readFile (builtins.fetchurl {
    url = "https://github.com/${username}.keys";
    sha256 = "0vzjaj4mabwdl71cr91k9smsmxlbkm55f12794n6j84vpdvyp7qk";
  }))));
in {
  imports = [
    ./hardware-configuration.nix
    ./headless-laptop.nix
  ];

  nix = {
    settings.trusted-users = ["@wheel"];
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "thesprotian";
    networkmanager.enable = true;
  };

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty
  };

  services.openssh.enable = true;
  users.users.agamemnon = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    initialHashedPassword = "$6$ZxJtQlZhhY8ZJjY$R6SqiPBtRh3YRD3Bnyprt0roT6mjvB4F6igRDISsADMJ56J.7YIoRbD9md4MFvQbSEsT1sQGWfxLLcWKV65lV/"; # hack me bro I dare you
    openssh.authorizedKeys.keys = fetchKeysList "ajaxbits";
  };

  programs.fish.enable = true;

  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.agamemnon.openssh.authorizedKeys.keys;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    kitty.terminfo
  ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
