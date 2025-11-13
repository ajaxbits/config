{
  nixpkgs,
  # microvm refers to microvm.nixosModules
  microvm,
  components,
  ...
}:
let
  hostName = "documents";

  pkgs = import nixpkgs { system = "x86_64-linux"; };
in
{
  imports = [
    microvm.host
    components
  ];
  microvm.vms.${hostName} = {
    # The package set to use for the microvm. This also determines the microvm's architecture.
    # Defaults to the host system's package set if not given.
    inherit pkgs;

    # (Optional) A set of special arguments to be passed to the MicroVM's NixOS modules.
    specialArgs = {
      inherit hostName;
    };

    config = import ./configuration.nix;
  };
}
