{
  config,
  pkgs,
  ...
}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgs.lib.getName pkg) [
      "unifi-controller"
    ];

  services.unifi = {
    enable = true;
    unifiPackage = pkgs.unifi7;
    openFirewall = true;
  };
}
