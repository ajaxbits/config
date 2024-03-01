{
  config,
  pkgs,
  inputs,
  lib,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.dell-xps-15-9560
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = true;

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "ahci"
    "nvme"
    "usb_storage"
    "usbhid"
    "sd_mod"
    "rtsx_pci_sdmmc"
  ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-intel"];
  boot.extraModulePackages = [];
  boot.kernel.sysctl = {
    "fs.inotify.max_user_watches" = "1048576";
  };
  boot.kernelParams = ["acpi_rev_override=1"];
  boot.tmp.cleanOnBoot = true;

  environment.systemPackages = [
    pkgs.libsmbios
    pkgs.xorg.xf86inputsynaptics
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = ["noatime" "nodiratime" "discard"];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.bluetooth.enable = true;

  services.fstrim.enable = true;
  services.fstrim.interval = "daily";

  swapDevices = [{device = "/dev/disk/by-label/swap";}];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
