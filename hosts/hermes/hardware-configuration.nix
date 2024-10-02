{
  config,
  pkgs,
  inputs,
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.dell-xps-15-9560-intel
  ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usb_storage"
      "usbhid"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
    initrd.kernelModules = [ ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernel.sysctl = {
      "fs.inotify.max_user_watches" = "1048576";
    };
    kernelParams = [
      "acpi_rev_override=1"
      "i915.disable_power_well=0"
    ];
    tmp.cleanOnBoot = true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  networking.useDHCP = false;
  networking.interfaces.wlp2s0.useDHCP = true;

  environment.systemPackages = [
    pkgs.libsmbios
    pkgs.xorg.xf86inputsynaptics
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/ESP";
    fsType = "vfat";
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  services.fstrim.enable = true;
  services.fstrim.interval = "daily";

  swapDevices = [ { device = "/dev/disk/by-label/swap"; } ];

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
}
