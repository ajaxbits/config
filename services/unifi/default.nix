{pkgsUnfree, ...}: {
  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (pkgsUnfree.lib.getName pkg) [
      "unifi-controller"
    ];

  services.unifi = {
    enable = true;
    unifiPackage = pkgsUnfree.unifi7;
    mongodbPackage = pkgsUnfree.mongodb;
    maximumJavaHeapSize = 256;
    openFirewall = true;
  };
}
