{
  description = "NixOS configurations";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    custom.url = "github:ajaxbits/nixpkgs/paperless213-settings";
    unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";

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
    custom,
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
          ];
        };
        pkgsUnfree = unfree.legacyPackages.${system};
        pkgsUnstable = unstable.legacyPackages.${system};
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
          specialArgs = {inherit inputs self lib pkgs pkgsUnstable pkgsUnfree;};
          modules = [
            "${self}/hosts/patroclus/configuration.nix"
            "${self}/common"
            "${self}/components"
            {
              disabledModules = ["${nixpkgs}/nixos/modules/services/misc/paperless.nix"];
              imports = ["${custom}/nixos/modules/services/misc/paperless.nix"];
            }
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
