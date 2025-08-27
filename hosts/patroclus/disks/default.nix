{ config, ... }:
{
  imports = [
    ./disks.nix
    {
      _module.args = { inherit (config.networking) hostName; };
    }
  ];
}
