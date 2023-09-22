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
      {
        environment.systemPackages = [
          pkgs.arion
          pkgs.docker-client
        ];

        virtualisation.docker.enable = false;
        virtualisation.podman.enable = true;
        virtualisation.podman.dockerSocket.enable = true;
        virtualisation.podman.defaultNetwork.dnsname.enable = true;

        users.extraUsers.admin.extraGroups = ["podman"];
      }
    ]
    ++ myModules;
}
