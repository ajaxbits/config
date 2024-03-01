{
  description = "NixOS configurations";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    latest.url = "github:nixos/nixpkgs/master";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nur.url = "github:nix-community/NUR";

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
    comic-code = {
      url = "github:ajaxbits/comic-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim.url = "github:ajaxbits/neovim-flake";
    neovim.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    latest,
    unfree,
    unstable,
    flake-parts,
    home-manager,
    comic-code,
    neovim,
    nur,
    agenix,
    nixos-hardware, # deadnix: skip
    caddy,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            agenix.packages.${system}.default
          ];
        };
      };
    }
    // (
      let
        inherit (pkgs) lib;

        system = "x86_64-linux";
        user = "admin";

        pkgs = import nixpkgs {inherit system;};
        pkgsLatest = import latest {inherit system;};
        pkgsUnfree = unfree.legacyPackages.${system};
        pkgsUnstable = unstable.legacyPackages.${system};

        overlays = import ./overlays.nix {inherit inputs system;};

        specialArgs = {inherit inputs self lib pkgs pkgsLatest pkgsUnstable pkgsUnfree overlays user;};
      in {
        nixosConfigurations = {
          patroclus = nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            modules = [
              "${self}/hosts/patroclus/configuration.nix"
              "${self}/common"
              "${self}/components"
              home-manager.nixosModules.home-manager
            ];
          };
          hermes = nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            modules = [
              "${self}/hosts/hermes/configuration.nix"
              "${self}/common"
              "${self}/components"
              home-manager.nixosModules.home-manager
            ];
          };
        };
      }
    );

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };
}
