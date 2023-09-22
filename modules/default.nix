{
  inputs,
  self,
  pkgs,
  lib,
  ...
}: let
  modulesLocation = "${self}/modules";
  myModules =
    lib.mapAttrsToList (modulePath: _: "${modulesLocation}/${modulePath}")
    (lib.filterAttrs (path: value: value == "directory") (builtins.readDir modulesLocation));
in {
  imports =
    [
      inputs.agenix.nixosModules.age
      inputs.arion.nixosModules.arion
    ]
    ++ myModules;
}
