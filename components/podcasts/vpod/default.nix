{
  inputs,
  ...
}:
{
  imports = [
    inputs.microvm.nixosModules.host
    ./networking.nix
    ./options.nix
    ./vm.nix
  ];
}
