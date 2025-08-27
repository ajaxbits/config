{ hostName, ... }:
{
  imports = [
    ./authentik.nix
    ./disks
    ./hardware-configuration.nix
  ];
  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  networking = {
    inherit hostName;
    networkmanager.enable = true;
    firewall.enable = false;
  };

  components = {
    audiobookshelf = {
      enable = true;
      backups.enable = true;
      backups.healthchecksUrl = "https://hc-ping.com/e7c85184-7fcf-49a2-ab4f-7fae49a80d9c";
    };
    binary-cache.enable = true;
    bookmarks = {
      enable = true;
      backups = {
        enable = true;
        healthchecksUrl = "https://hc-ping.com/6bbcb9d3-52c5-48e7-b9f8-20b58264f57e";
      };
    };
    caddy = {
      enable = true;
      cloudflare.enable = true;
    };
    cd.enable = true;
    cloudflared.enable = true;
    development.forge.enable = true;
    ebooks.enable = true;
    filesystems = {
      bcachefs.enable = false;
      zfs.enable = true;
    };
    iot.esphome.enable = false;
    mediacenter = {
      enable = true;
      intel.enable = true;
      invidious.enable = false;
      linux-isos.enable = true;
    };
    miniflux.enable = true;
    monitoring.enable = true;
    networking.unifi.enable = true;
    documents = {
      paperless = {
        enable = true;
        backups.enable = true;
        backups.healthchecksUrl = "https://hc-ping.com/2667f610-dc7f-40db-a753-31101446c823";
      };
      stirlingPdf.enable = true;
    };
    # photos.enable = true;
    tailscale = {
      enable = true;
      initialAuthKey = "tskey-auth-kCJEH64CNTRL-KDvHnxkzYEQEwhQC9v2L8QgQ8Lu8HcYnN";
      tags = [
        "ajax"
        "homelab"
        "nixos"
      ];
      advertiseExitNode = true;
      advertiseRoutes = [ "172.22.0.0/15" ];
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
