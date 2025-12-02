{ pkgs, ... }:
{
  config = {
    nixpkgs.overlays = [
      (final: prev: {
        inherit (prev.lixPackageSets.stable)
          colmena
          nix-eval-jobs
          nix-fast-build
          nixpkgs-review
          ;
      })
    ];
    nix = {
      package = pkgs.lixPackageSets.stable.lix;
      settings = {
        trusted-users = [ "@wheel" ];
        extra-experimental-features = [
          "nix-command"
          "flakes"
        ];
      };
      optimise.automatic = true;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 30d";
      };

    };
  };
}
