{ config, pkgs, ... }:
let
  disksCfg = config.disko.devices.disk;
  bootPaths = builtins.mapAttrs (
    _: diskConfig: diskConfig.content.partitions.ESP.content.mountpoint
  ) disksCfg;
in
{
  boot = {
    kernelParams = [ "elevator=none" ]; # https://grahamc.com/blog/nixos-on-zfs/
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = disksCfg.a.content.partitions.ESP.content.mountpoint;
      };
    };
    supportedFilesystems = [ "zfs" ];
  };


  # if the backup boot isn't present, don't fail
  fileSystems.${bootPaths.b}.options = [ "nofail" ];

  systemd.services.boot-sync = {
    description = "Mirror boot files to backup NVMe";
    wantedBy = [ "multi-user.target" ];
    after = [ "nixos-rebuild.service" ];
    path = [ pkgs.rsync ];

    # run every time a new generation appears
    startAt = "multi-user.target";

    script = ''
      set -euo pipefail
      rsync -a --delete ${bootPaths.a}/ ${bootPaths.b}
      bootctl install --esp-path=${bootPaths.b}
    '';
  };
}
