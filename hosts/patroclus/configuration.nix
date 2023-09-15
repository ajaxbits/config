# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{
  config,
  pkgs,
  ...
}: {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  nix = {
    settings.trusted-users = ["@wheel"];
    settings.auto-optimise-store = true;
    settings.extra-experimental-features = ["nix-command" "flakes"];
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "patroclus"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true; # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/Chicago";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  # i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.layout = "us";
  # services.xserver.xkbOptions = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # sound.enable = true;
  # hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.admin = {
    isNormalUser = true;
    extraGroups = ["wheel"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      neovim
      tmux
    ];
    initialHashedPassword = "$6$ZxJtQlZhhY8ZJjY$R6SqiPBtRh3YRD3Bnyprt0roT6mjvB4F6igRDISsADMJ56J.7YIoRbD9md4MFvQbSEsT1sQGWfxLLcWKV65lV/"; # hack me bro I dare you
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCs1jS9VyF8cR913jEJAhmtz1xPUdGwGLwmun8mbPnaCAS+4OJlxgxhBQTuVch2SjPdGck7LXtmZWF55XO8Na342miEbdKDpMAEf+MR3iA8sxDECwrqvtiwRGgrXtQuR3qXRbrrKn9WTqjKZyng5tcsvcIlQSc7ig23AuF9yifMzyqvSYvaVirS8BKorSDY9aLCqbnH1KTDQWV5H4t4rmF9ixSXAiVhYGu6AXTT4xm7ND+JX7+l91TPHk8e2Sjy/97CjVwivkRtJJzw1szPZqxaDlKm5c+na4fgWlG/zZ1bAXhB4o4S5Js6nbmVtzGiiYvUquGC8BQtLkzMxmyX5jD+17f87vZ5nGH7NbSG52poEha4kZVudmZHN/MoIdJnTRW5NoQO2VqPHDCLLHbZ/6RvNoU81mHMiTTMJpc3mTBUxOcLWREG5RlueA4SQ4B9nqTLlO13iAR8TGGfIRqX1YkhW7GIbhZHacPukDTNuH7A7hjJHapKS36OEUpPgdU+6JNLVAKIG7AJrjfhCv0bowjESyZr89ihub5yZGx5VvrK5COe/sKgqWgNS6hIiSH6ASwBi4QKMeamdrYUm1nyZu9KZrRb+p/vwumnkeCY/m7tmqCLUG4+FHfBvcDjWlGzzidEFSywfsa3O65y4AIdApk+MbeTU6o/s1RsNNTITuJTpQ=="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1HH8/qgcU63wichBiB5nvSv0+9B9xxWdy2AYQr3oyr"
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    neofetch
    tmux
    wget
    kitty.terminfo
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
