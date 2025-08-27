{ config, ... }:
let
  dataPaths = import ./dataPaths.nix;
in
{
  _module.args = {
    inherit dataPaths;
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
