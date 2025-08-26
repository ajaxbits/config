{
  disks,
  hostName,
  lib,
  ...
}:
let
  hostId = builtins.substring 0 8 (builtins.hashString "sha256" hostName);
  sectorSizeBytes = 512;

  rootPool = "zroot";

  # local
  #     /nix
  # system
  #     /root
  #     /var
  # srv
  #     /containers
  #     /media
  #     /documents => encrypted
  #     /config
in
rec {
  ### DISKS ###
  disko.devices = {
    disk = lib.genAttrs disks (device: {
      inherit device;
      name = lib.removePrefix "/dev/" device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "64M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "umask=0077" ];
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = rootPool;
            };
          };
        };
      };
    });

    zpool = {
      ${rootPool} = {
        type = "zpool";
        mode = "mirror";

        # zpool properties
        options = {
          ashift = builtins.getAttr (builtins.toString sectorSizeBytes) {
            # https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
            "512" = "9";
            "4000" = "12";
            "8000" = "13";
          };
          autotrim = "on";
        };

        # zfs properties
        rootFsOptions = {
          # https://jrs-s.net/2018/08/17/zfs-tuning-cheat-sheet/
          acltype = "posixacl";
          atime = "off";
          canmount = "off";
          compression = "lz4";
          dnodesize = "auto";
          mountpoint = "none";
          # https://rubenerd.com/forgetting-to-set-utf-normalisation-on-a-zfs-pool/
          normalization = "formD";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };

        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^${rootPool}@blank$' || zfs snapshot ${rootPool}@blank";

        datasets = {
          reserved = {
            type = "zfs_fs";
            options = {
              mountpoint = "none";
              reservation = "10GiB";
            };
          };

          system = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          local = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          srv = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };

          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              atime = "off";
              canmount = "on";
              mountpoint = "legacy";
              recordsize = "1M";
              reservation = "20G";
              "com.sun:auto-snapshot" = "false";
            };
          };

          "system/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options.mountpoint = "legacy";
          };
          "system/var" = {
            type = "zfs_fs";
            mountpoint = "/var";
            options.mountpoint = "legacy";
          };

          "srv/media" = {
            type = "zfs_fs";
            mountpoint = "/srv/media";
            options.mountpoint = "legacy";
          };
          "srv/media/audiobooks" = {
            type = "zfs_fs";
            mountpoint = "/srv/media/audiobooks";
            options.mountpoint = "legacy";
          };
          "srv/documents" = {
            type = "zfs_fs";
            mountpoint = "/srv/documents";
            options.mountpoint = "legacy";
          };
          "srv/config" = {
            type = "zfs_fs";
            mountpoint = "/srv/config";
            options.mountpoint = "legacy";
          };
          "srv/containers" = {
            type = "zfs_fs";
            mountpoint = "/srv/containers";
            options.mountpoint = "legacy";
          };
        };
      };
    };
  };

  ### FILESYSTEM ###
  networking.hostId = hostId;
  boot = {
    kernelParams = [ "elevator=none" ]; # https://grahamc.com/blog/nixos-on-zfs/
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      efi.efiSysMountPoint = "/boot/efi-0";
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = disko.devices.zpool.${rootPool}.options.autotrim == "on";
  };
  fileSystems."/srv".neededForBoot = true;
}
