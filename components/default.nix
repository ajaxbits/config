{
  inputs,
  self,
  lib,
  ...
}: let
  componentsLocation = "${self}/components";
  components =
    lib.mapAttrsToList (componentsPath: _: "${componentsLocation}/${componentsPath}")
    (lib.filterAttrs (_path: value: value == "directory") (builtins.readDir componentsLocation));
in {
  imports =
    [
      inputs.agenix.nixosModules.age
      inputs.arion.nixosModules.arion
    ]
    ++ components;
}
