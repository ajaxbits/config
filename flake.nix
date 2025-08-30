{
  description = "NixOS configurations";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";
    mypkgs.url = "github:ajaxbits/nixpkgs/edl-udev-rules";

    authentik-nix.url = "github:marcelcoding/authentik-nix";

    lix-module = {
      url = "https://git.lix.systems/lix-project/nixos-module/archive/2.93.2-1.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      disko,
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
          devShells =
            let
              commonPkgs = with pkgs; [
                agenix.packages.${system}.default
                bashInteractive
              ];
            in
            {
              default = pkgs.mkShell {
                packages = commonPkgs;
              };
              installer = pkgs.mkShell {
                packages = [
                  disko.packages.${system}.disko
                  pkgs.git
                  pkgs.jq
                  pkgs.neovim
                  pkgs.nix-output-monitor
                ] ++ commonPkgs;
              };
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
              "${self}/common"
              "${self}/components"
              "${self}/hosts/patroclus/configuration.nix"
              home-manager.nixosModules.home-manager
              inputs.authentik-nix.nixosModules.default
              inputs.disko.nixosModules.disko
              lix-module.nixosModules.default
            ];
          };
          patroclusStripped = nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            modules = [
              "${self}/common"
              "${self}/components"
              (import ./hosts/patroclus/configuration.nix {
                inherit lib;
                isStripped = true;
              })
              home-manager.nixosModules.home-manager
              inputs.disko.nixosModules.disko
              lix-module.nixosModules.default
            ];
          };
          hermes = nixpkgs.lib.nixosSystem {
            inherit specialArgs system;
            modules = [
              "${self}/common"
              "${self}/components"
              "${self}/hosts/hermes/configuration.nix"
              home-manager.nixosModules.home-manager
              inputs.nur.modules.nixos.default
              lix-module.nixosModules.default
            ];
          };
        };
    };

  nixConfig = {
    extra-substituters = [
      "https://cache.nix.ajax.casa/default?priority=10"
      "https://cache.garnix.io"
      "https://cache.lix.systems"
      "https://cache.nix.ajax.casa/default?priority=10"
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "default:UWyYKJgYFtej9lMrKcS5imS+WVuVRS6hKi9yaRL1g0s="
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
      "default:UWyYKJgYFtej9lMrKcS5imS+WVuVRS6hKi9yaRL1g0s="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE="
    ];
  };
}
