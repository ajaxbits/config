{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    deploy-rs.url = "github:serokell/deploy-rs";
    arion.url = "github:hercules-ci/arion?rev=09ef2d13771ec1309536bbf97720767f90a5afa7";
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    unfree,
    unstable,
    flake-parts,
    deploy-rs,
    arion,
    agenix,
    ...
  } @ inputs:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-darwin" "x86_64-darwin"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.bashInteractive
            deploy-rs.packages.${system}.default
            pkgs.arion
            agenix.packages.${system}.default
          ];
        };
      };
    }
    // (
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        pkgsUnfree = unfree.legacyPackages.${system};
        deployPkgs = import nixpkgs {
          inherit system;
          overlays = [
            deploy-rs.overlay
            (self: super: {
              deploy-rs = {
                inherit (pkgs) deploy-rs;
                lib = super.deploy-rs.lib;
              };
            })
          ];
        };
        utils = import ./util/include.nix {lib = pkgs.lib;};
      in {
        nixosConfigurations.agamemnon = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs self pkgs pkgsUnfree;};
          modules = [
            {imports = utils.includeDir ./modules/base;}
            (import ./modules/cd.nix {
              inherit agenix self;
              config = self.nixosConfigurations.agamemnon.config;
            })
            arion.nixosModules.arion
            ./hosts/agamemnon/configuration.nix
          ];
        };

        nixosConfigurations.patroclus = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs self pkgs pkgsUnfree;};
          modules = [
            (import ./modules/cd.nix {
              inherit agenix self;
              config = self.nixosConfigurations.patroclus.config;
            })
            ./hosts/patroclus/configuration.nix
            {
              # we have to use unstable modules for tailscale for now to get good options
              # TODO: re-evaluate in 23.11
              disabledModules = ["${nixpkgs}/nixos/modules/services/networking/tailscale.nix"];
              imports = [
                "${self}/modules/tailscale.nix"
                "${unstable}/nixos/modules/services/networking/tailscale.nix"
              ];

              modules.tailscale = {
                enable = true;
                initialAuthKey = "tskey-auth-kWKfYg4CNTRL-ivZtvUWAJ9RbktPCLGaDFRRXUqYCpr3h";
                mullvad = true;
                tags = ["homelab" "nixos"];
              };
            }
          ];
        };

        nixosConfigurations.thesprotian = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs self;};
          modules = [
            {imports = utils.includeDir ./modules/base;}
            (import ./modules/cd.nix {
              inherit agenix self;
              config = self.nixosConfigurations.agamemnon.config;
            })
            arion.nixosModules.arion
            ./hosts/thesprotian/configuration.nix
          ];
        };

        deploy.nodes.agamemnon = {
          hostname = "agamemnon";
          fastConnection = true;
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.agamemnon;
          };
        };

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
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
