{
  hostName,
  sectorSizeBytes,
  rootPoolName,
  ...
}:
let
  mkDisk =
    { name, device }:
    {
      inherit name device;
      type = "disk";
      content = {
        type = "table";
        format = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              bootable = true;
              format = "vfat";
              mountpoint = "/boot/${name}";
              mountOptions = [ "umask=0077" ]; # TODO: analyze
            };
          };
          swap = {
            size = "8G";
            type = "8200";
            label = "swap-${name}";
            content = {
              type = "swap";
              randomEncryption = true;
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = rootPoolName;
            };
          };
        };
      };
    };
in
rec {
  imports = [ (import ./zpool.nix { inherit hostName rootPoolName sectorSizeBytes; }) ];
  disko.devices.disk = {
    a = mkDisk {
      name = "a";
      device = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U6NU0Y702592E";
    };
    b = mkDisk {
      name = "b";
      device = "/dev/disk/by-id/nvme-Samsung_SSD_990_EVO_Plus_2TB_S7U6NJ0Y709421M";
    };
  };

  swapDevices = builtins.map (disk: {
    device = "/dev/disk/by-label/${disk.content.partitions.swap.label}";
  }) (builtins.attrValues disko.devices.disk);
}
