{
  hostName,
  rootPoolName,
  sectorSizeBytes,
  ...
}:
let
  mkDisk =
    { name, device }:
    {
      inherit name device;
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/${name}";
              mountOptions = [ "umask=0077" ]; # TODO: analyze
            };
          };
          swap = {
            size = "8G";
            type = "8200";
            label = "swap-${name}";
            content.type = "swap";
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
      device = "/dev/REPLACEME";
    };
    b = mkDisk {
      name = "b";
      device = "/dev/REPLACEME";
    };
  };

  swapDevices = builtins.map (disk: {
    device = "/dev/disk/by-label/${disk.content.partitions.swap.label}";
  }) (builtins.attrValues disko.devices.disk);
}
