{
  hostName,
  rootPoolName,
  sectorSizeBytes,
  dataPaths ? (import ./dataPaths.nix),
  ...
}:
let
  hostId = builtins.substring 0 8 (builtins.hashString "sha256" hostName);
in
rec {
  ### GENERAL ZFS CONFIG ###
  networking.hostId = hostId;
  services.zfs = {
    autoScrub.enable = true;
    trim.enable = disko.devices.zpool.${rootPoolName}.options.autotrim == "on";
  };
  fileSystems."/srv".neededForBoot = true;

  ### ZPOOL ###
  disko.devices.zpool.${rootPoolName} = {
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

    postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^${rootPoolName}@blank$' || zfs snapshot ${rootPoolName}@blank";

    datasets = {

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

      reserved = {
        type = "zfs_fs";
        options = {
          mountpoint = "none";
          reservation = "10GiB";
        };
      };

      local = {
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

      system = {
        type = "zfs_fs";
        options.mountpoint = "none";
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

      srv = {
        type = "zfs_fs";
        mountpoint = "/srv";
        options.mountpoint = "legacy";
      };
      "srv/media" = {
        type = "zfs_fs";
        mountpoint = dataPaths.media;
        options.mountpoint = "legacy";
      };
      "srv/media/audiobooks" = {
        type = "zfs_fs";
        mountpoint = dataPaths.audiobooks;
        options.mountpoint = "legacy";
      };
      "srv/documents" = {
        type = "zfs_fs";
        mountpoint = dataPaths.documents;
        options.mountpoint = "legacy";
      };
      "srv/config" = {
        type = "zfs_fs";
        mountpoint = dataPaths.config;
        options.mountpoint = "legacy";
      };
      "srv/containers" = {
        type = "zfs_fs";
        mountpoint = dataPaths.containers;
        options.mountpoint = "legacy";
      };
    };
  };
}
