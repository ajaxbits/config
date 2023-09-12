{
  config,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
in {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "unifi-controller"
    ];

  services.autoUpgrade.flags = pkgs.lib.mkAfter ["--impure"];
  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi7;
    openFirewall = true;
  };
}
