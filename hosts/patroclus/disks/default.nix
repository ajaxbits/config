let
  dataPaths = import ./dataPaths.nix;
in
{
  _module.args = {
    inherit dataPaths;
  };

  imports = [
    ./boot.nix
    ./disks.nix
    ./snapshots.nix
  ];
}
