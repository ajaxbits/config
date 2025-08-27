{
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
{
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
}
