{
  description = "A basic flake with a shell";
  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.0.tar.gz";
    unfree.url = "github:numtide/nixpkgs-unfree";
    unfree.inputs.nixpkgs.follows = "nixpkgs";

    flake-parts.url = "github:hercules-ci/flake-parts";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    deploy-rs.url = "github:serokell/deploy-rs";
    arion.url = "github:hercules-ci/arion";
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
    unfree,
    unstable,
    flake-parts,
    deploy-rs,
    arion,
    agenix,
    nixos-hardware,
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
            pkgs.arion
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
            (_self: super: {
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
              components = {
                cd.enable = true;
                caddy.enable = true;
                monitoring.enable = true;
                miniflux.enable = true;
                mediacenter = {
                  enable = true;
                  intel.enable = true;
                  linux-isos.enable = true;
                  youtube.enable = false;
                };
                paperless = {
                  enable = true;
                  backups.enable = true;
                  backups.healthchecksUrl = "https://hc-ping.com/2667f610-dc7f-40db-a753-31101446c823";
                };
                audiobookshelf.enable = true;
                ebooks.enable = true;
                tailscale = {
                  enable = true;
                  initialAuthKey = "tskey-auth-kCJEH64CNTRL-KDvHnxkzYEQEwhQC9v2L8QgQ8Lu8HcYnN";
                  tags = ["ajax" "homelab" "nixos"];
                  advertiseExitNode = true;
                  advertiseRoutes = ["172.22.0.0/15"];
                };
                zfs.enable = true;
                bcachefs.enable = true;
              };
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

        nixosModules = let
          modulesLocation = "${self}/components";
        in
          lib.mapAttrs (modulePath: _: import "${modulesLocation}/${modulePath}")
          (lib.filterAttrs (_path: value: value == "directory") (builtins.readDir modulesLocation));
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
