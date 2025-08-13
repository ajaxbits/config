{
  config,
  pkgs,
  ...
}:
let
  hostName = "arachne";
in
{
  imports = [
    ./configtxt.nix
    ./disks.nix
  ];

  # Time & hostname
  time.timeZone = "America/Chicago";

  networking = {
    inherit hostName;
    domain = "ajax.casa";

    # Safe(ish) network defaults + iwd
    useNetworkd = true;
    firewall.allowedUDPPorts = [ 5353 ];
    wireless.enable = false;
    wireless.iwd = {
      enable = true;
      settings = {
        Network = {
          EnableIPv6 = true;
          RoutePriorityOffset = 300;
        };
        Settings.AutoConnect = true;
      };
    };
  };
  systemd.network.networks = {
    "99-ethernet-default-dhcp".networkConfig.MulticastDNS = "yes";
    "99-wireless-client-dhcp".networkConfig.MulticastDNS = "yes";
  };
  systemd.services = {
    systemd-networkd.stopIfChanged = false;
    systemd-resolved.stopIfChanged = false;
  };

  # Console / udev niceties
  # imports = [ ./modules/nice-looking-console.nix ];
  services.udev.extraRules = ''
    # Ignore partitions with "Required Partition" GPT partition attribute
    # On our RPis this is firmware (/boot/firmware) partition
    ENV{ID_PART_ENTRY_SCHEME}=="gpt", \
      ENV{ID_PART_ENTRY_FLAGS}=="0x1", \
      ENV{UDISKS_IGNORE}="1"
  '';

  # Packages
  environment.systemPackages = with pkgs; [
    nvim
    raspberry-pi-eeprom
    tree
  ];

  # SSH + sudo + polkit
  security = {
    polkit.enable = true;
    sudo.enable = false;
    doas.enable = false;
  };

  # Stateless: follow latest
  system.stateVersion = config.system.nixos.release;

  # Useful tags
  system.nixos.tags =
    let
      cfg = config.boot.loader.raspberryPi;
    in
    [
      hostName
      cfg.bootloader
      config.boot.kernelPackages.kernel.version
    ];

  # tmpfs for /tmp
  boot.tmp.useTmpfs = true;
}
