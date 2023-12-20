{
  imports = [
    ./hardware-configuration.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "patroclus";
  networking.hostId = "a7d14532";
  networking.networkmanager.enable = true;

  networking.firewall.enable = false;
  
  services.ntfy-sh.enable = true;
  services.ntfy-sh.settings.listen-http = "";
  services.ntfy-sh.settings.listen-unix = "/run/ntfy-sh/ntfy.sock";
  systemd.tmpfiles.rules = [
    "d /run/ntfy-sh 0777 ntfy-sh ntfy-sh - -"
    # "f ${cfg.settings.cache-file} 0600 ${cfg.user} ${cfg.group} - -"
  ];
  services.ntfy-sh.settings.listen-unix-mode = 777;
  services.ntfy-sh.settings.base-url = "https://ntfy.ajax.casa";
  services.caddy.virtualHosts."https://ntfy.ajax.casa".extraConfig = ''
        encode gzip zstd
        reverse_proxy unix//run/ntfy-sh/ntfy.sock
        import cloudflare
      '';
  

  components = {
    audiobookshelf = {
      enable = true;
      backups.enable = true;
      backups.healthchecksUrl = "https://hc-ping.com/e7c85184-7fcf-49a2-ab4f-7fae49a80d9c";
    };
    caddy = {
      enable = true;
      cloudflare.enable = true;
    };
    cd.enable = true;
    ebooks.enable = true;
    filesystems = {
      bcachefs.enable = false;
      zfs.enable = true;
    };
    iot.esphome.enable = true;
    mediacenter = {
      enable = true;
      intel.enable = true;
      linux-isos.enable = true;
    };
    miniflux.enable = true;
    monitoring.enable = true;
    networking.unifi.enable = true;
    paperless = {
      enable = true;
      backups.enable = true;
      backups.healthchecksUrl = "https://hc-ping.com/2667f610-dc7f-40db-a753-31101446c823";
    };
    tailscale = {
      enable = true;
      initialAuthKey = "tskey-auth-kCJEH64CNTRL-KDvHnxkzYEQEwhQC9v2L8QgQ8Lu8HcYnN";
      tags = ["ajax" "homelab" "nixos"];
      advertiseExitNode = true;
      advertiseRoutes = ["172.22.0.0/15"];
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
