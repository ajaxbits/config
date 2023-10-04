{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "github:Nixos/nixpkgs/nixos-23.05";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    deploy-rs.url = "github:serokell/deploy-rs";
    arion.url = "github:hercules-ci/arion";
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
    nixos-hardware,
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
        pkgsUnstable = unstable.legacyPackages.${system};
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

        lib = pkgs.lib;
        utils = import ./util/include.nix {lib = pkgs.lib;};
      in {
        nixosConfigurations.patroclus = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {inherit inputs self lib pkgs pkgsUnstable pkgsUnfree;};
          modules = [
            # Hardware
            nixos-hardware.nixosModules.common-pc-ssd
            nixos-hardware.nixosModules.common-cpu-intel
            nixos-hardware.nixosModules.common-gpu-intel

            # Base config
            "${self}/hosts/patroclus/configuration.nix"
            "${self}/common"
            "${self}/components"

            # Modules
            {
              # we have to use unstable modules for tailscale for now to get good options
              # TODO: re-evaluate in 23.11
              disabledModules = ["${nixpkgs}/nixos/modules/services/networking/tailscale.nix"];
              imports = [
                "${unstable}/nixos/modules/services/networking/tailscale.nix"
              ];
            }
            "${self}/services/forgejo"
            {
              components.cd.enable = true;
              components.monitoring.enable = true;
              components.miniflux.enable = true;
              components.mediacenter = {
                enable = true;
                intel.enable = true;
                linux-isos.enable = true;
                youtube.enable = false;
              };
              components.paperless = {
                enable = true;
                backups.enable = true;
                backups.healthchecksUrl = "https://hc-ping.com/2667f610-dc7f-40db-a753-31101446c823";
              };
              components.audiobookshelf.enable = true;
              components.tailscale = {
                enable = true;
                initialAuthKey = "tskey-auth-kCJEH64CNTRL-KDvHnxkzYEQEwhQC9v2L8QgQ8Lu8HcYnN";
                tags = ["ajax" "homelab" "nixos"];
                advertiseExitNode = true;
                advertiseRoutes = ["172.22.0.0/15"];
              };
              components.zfs.enable = true;
            }
          ];
        };

        deploy.nodes.agamemnon = {
          hostname = "patroclus";
          fastConnection = true;
          profiles.system = {
            sshUser = "root";
            user = "root";
            path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.patroclus;
          };
        };

        # This is highly advised, and will prevent many possible mistakes
        checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

        nixosModules = let
          modulesLocation = "${self}/components";
        in
          lib.mapAttrs (modulePath: _: import "${modulesLocation}/${modulePath}")
          (lib.filterAttrs (path: value: value == "directory") (builtins.readDir modulesLocation));
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
