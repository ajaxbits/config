{
  description = "NixOS configurations";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    latest.url = "github:nixos/nixpkgs/master";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";

    jnsgruk.url = "github:jnsgruk/nixos-config";
    jnsgruk.inputs.nixpkgs.follows = "unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    deploy-rs.url = "github:serokell/deploy-rs";
    agenix = {
      url = "https://flakehub.com/f/ryantm/agenix/0.14.0.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # custom pkgs
    caddy = {
      url = "github:ajaxbits/nixos-caddy-patched";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    latest,
    unfree,
    unstable,
    flake-parts,
    deploy-rs,
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
            deploy-rs.packages.${system}.default
            agenix.packages.${system}.default
          ];
        };
      };
    }
    // (
      let
        system = "x86_64-linux";
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (_self: _super: {
              caddy-patched = caddy.packages.${system}.caddy;
            })
            inputs.jnsgruk.overlays.additions
          ];
        };
        pkgsLatest = import latest {
          inherit system;
        };
        pkgsUnfree = unfree.legacyPackages.${system};
        pkgsUnstable = unstable.legacyPackages.${system};
        pkgsJnsgruk = inputs.jnsgruk;
        deployPkgs = import nixpkgs {
          inherit system;
          overlays = [
            deploy-rs.overlay
            (_self: super: {
              deploy-rs = {
                inherit (pkgs) deploy-rs;
                inherit (super.deploy-rs) lib;
              };
            })
          ];
        };

        inherit (pkgs) lib;
      in {
        nixosConfigurations.patroclus = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs self lib pkgs pkgsLatest pkgsUnstable pkgsUnfree pkgsJnsgruk;};
          modules = [
            "${self}/hosts/patroclus/configuration.nix"
            "${self}/common"
            "${self}/components"
          ];
        };

        deploy.nodes.patroclus = {
          hostname = "patroclus";
          fastConnection = true;
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.patroclus;
          };
        };

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (_system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
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
