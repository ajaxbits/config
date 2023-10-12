{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  nixpkgs.config.allowUnfree = true; # required for mac firmware blobs

  boot = {
    initrd.availableKernelModules = ["uhci_hcd" "ehci_pci" "ahci" "firewire_ohci" "usbhid" "usb_storage" "sd_mod" "sr_mod" "sdhci_pci"];
    initrd.kernelModules = [];
    kernelModules = ["kvm-intel" "wl"];
    extraModulePackages = [config.boot.kernelPackages.broadcom_sta];
  };

  # ssd inside
  services.fstrim.enable = true;
  services.fstrim.interval = "daily";

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8006f7a8-32f2-4174-ad50-96e9d4c8518d";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7C28-9A43";
    fsType = "vfat";
  };

  swapDevices = [
    {device = "/dev/disk/by-uuid/3d247676-330c-4452-ad58-bb4befe5cbea";}
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp2s0f0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
