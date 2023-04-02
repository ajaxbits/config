# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  self,
  config,
  pkgs,
  lib,
  ...
}: let
  fetchKeysList = username: (lib.remove "" (lib.splitString "\n" (builtins.readFile (builtins.fetchurl {
    url = "https://github.com/${username}.keys";
    sha256 = "0x7sjs9v6wixv35y7gz7a0qya40klsalvf9l7jxpn8jjx1n1lhdq";
  }))));
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    "${self}/services/paperless"
    (import "${self}/services/calibre-web" {
      inherit lib;
      dataDir = "/data";
      useIpv6 = false;
    })
    "${self}/services/audiobookshelf"
    "${self}/services/monitoring"
    "${self}/services/watchtower"
  ];

  nix.settings.trusted-users = ["@wheel"];
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "agamemnon";
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkbOptions in tty.
  };

  services.upower.ignoreLid = true;
  services.logind.lidSwitch = "ignore";
  services.logind.extraConfig = "HandleLidSwitch=ignore";

  systemd.services.disable-screen-light = {
    script = ''
      sleep 10m
      grep -q close /proc/acpi/button/lid/*/state
      if [ $? = 0 ]; then
        ${pkgs.light}/bin/light -S 0
      fi
    '';
    wantedBy = ["multi-user.target"];
  };

  users.users.agamemnon = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    initialHashedPassword = "$6$ZxJtQlZhhY8ZJjY$R6SqiPBtRh3YRD3Bnyprt0roT6mjvB4F6igRDISsADMJ56J.7YIoRbD9md4MFvQbSEsT1sQGWfxLLcWKV65lV/"; # hack me bro I dare you
    openssh.authorizedKeys.keys = fetchKeysList "ajaxbits";
  };
  users.users.root.openssh.authorizedKeys.keys =
    config.users.users.agamemnon.openssh.authorizedKeys.keys;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    kitty.terminfo
  ];

  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
