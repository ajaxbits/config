{
  description = "NixOS configurations";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";
    mypkgs.url = "github:ajaxbits/nixpkgs/edl-udev-rules";

    authentik-nix.url = "github:nix-community/authentik-nix";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.91.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    agenix = {
      url = "https://flakehub.com/f/ryantm/agenix/0.14.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # custom pkgs
    caddy = {
      url = "github:ajaxbits/nixos-caddy-patched";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    centerpiece = {
      url = "github:friedow/centerpiece";
      inputs.nixpkgs.follows = "unstable";
    };
    neovim.url = "github:ajaxbits/nvim";
    nur.url = "github:nix-community/NUR";
  };

  outputs =
    {
      self,
      nixpkgs,
      unfree,
      unstable,
      flake-parts,
      home-manager,
      neovim,
      nur,
      agenix,
      nixos-hardware, # deadnix: skip
      lix-module,
      caddy,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, system, ... }:
        {
          devShells.default = pkgs.mkShell {
            packages = [
              pkgs.bashInteractive
              agenix.packages.${system}.default
            ];
          };
        };

      flake.nixosConfigurations =
        let
          inherit (pkgs) lib;

          system = "x86_64-linux";
          user = "admin";

          pkgs = import nixpkgs { inherit system; };
          pkgsUnfree = unfree.legacyPackages.${system};
          pkgsUnstable = import unstable { inherit system; };

          overlays = import ./overlays.nix { inherit inputs system pkgsUnfree; };

          specialArgs = {
            inherit
              inputs
              self
              system
              lib
              pkgsUnstable
              pkgsUnfree
              overlays
              user
              unstable
              ;
          };
        in
        {
          patroclus = nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            modules = [
              "${self}/hosts/patroclus/configuration.nix"
              "${self}/common"
              "${self}/components"
              home-manager.nixosModules.home-manager
              lix-module.nixosModules.default
              inputs.authentik-nix.nixosModules.default
            ];
          };
          hermes = nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            modules = [
              "${self}/hosts/hermes/configuration.nix"
              "${self}/common"
              "${self}/components"
              home-manager.nixosModules.home-manager
              lix-module.nixosModules.default
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://numtide.cachix.org"
      "https://cache.lix.systems"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
    ];
  };
}
