{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

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
    flake-utils,
    deploy-rs,
    arion,
    agenix,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      devShells.default = pkgs.mkShell {
        packages = [
          pkgs.bashInteractive
          deploy-rs.packages.${system}.default
          pkgs.arion
          agenix.packages.${system}.default
        ];
      };
    })
    // (
      let
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        utils = import ./util/include.nix {lib = pkgs.lib;};
      in {
        nixosConfigurations.agamemnon = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit inputs self;};
          modules = [
            {
              imports = utils.includeDir ./modules/base;
            }
            agenix.nixosModules.age
            arion.nixosModules.arion
            ./agamemnon/configuration.nix
          ];
        };

        deploy.nodes.agamemnon = {
          hostname = "100.103.179.99";
          fastConnection = true;
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.agamemnon;
          };
        };

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
      }
    );
}
