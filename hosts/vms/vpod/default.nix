{ inputs, ... }:
let
  hostName = "vpod";

  pkgs = import inputs.nixpkgs { system = "x86_64-linux"; };
in
{
  imports = [
    inputs.microvm.nixosModules.host
  ];
  microvm.vms.${hostName} = {
    # The package set to use for the microvm. This also determines the microvm's architecture.
    # Defaults to the host system's package set if not given.
    inherit pkgs;

    # (Optional) A set of special arguments to be passed to the MicroVM's NixOS modules.
    specialArgs = {
      inherit hostName;
    };

    extraModules = [
      inputs.agenix.nixosModules.age
      inputs.vpod.nixosModules.default
    ];

    config = import ./configuration.nix;
  };
}
