{ config, ... }:
{
  _module.args = {
    inherit (config.networking) hostName;
    rootPoolName = "zroot";
    sectorSizeBytes = 512;
  };

  imports = [
    ./boot.nix
    ./disks.nix
    ./zpool.nix
  ];
}
