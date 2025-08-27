{ config, pkgs, ... }:
let
  disksCfg = config.disko.devices.disk;
in
{
  boot = {
    kernelParams = [ "elevator=none" ]; # https://grahamc.com/blog/nixos-on-zfs/
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = disksCfg.a.content.partitions.ESP.content.mountpoint;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };
  systemd.services.boot-sync = {
    description = "Mirror boot files to backup NVMe";
    wantedBy = [ "multi-user.target" ];
    after = [ "nixos-rebuild.service" ];
    path = [ pkgs.rsync ];

    # run every time a new generation appears
    startAt = "multi-user.target";

    script =
      let
        bootPaths = builtins.mapAttrs (
          _: diskConfig: diskConfig.content.partitions.ESP.content.mountpoint
        ) disksCfg;
      in
      ''
        set -euo pipefail
        rsync -a --delete ${bootPaths.a} ${bootPaths.b}
        bootctl install --esp-path=${bootPaths.b} --entry-token=auto
      '';
  };
}
