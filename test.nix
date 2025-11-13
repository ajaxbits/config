# microvm refers to microvm.nixosModules
{
  hostName,
  nixpkgs,
  microvm,
  ...
}:
{
  imports = [ microvm.host ];
  microvm.vms = {
    test1 = {
      # The package set to use for the microvm. This also determines the microvm's architecture.
      # Defaults to the host system's package set if not given.
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      # (Optional) A set of special arguments to be passed to the MicroVM's NixOS modules.
      #specialArgs = {};

      # The configuration for the MicroVM.
      # Multiple definitions will be merged as expected.
      config = {

        environment.etc."machine-id" = {
          mode = "0644";
          text = "b7a4f2c83e914e1ebc3a4a2e8e9d5f01" + "\n";
        };

        services.openssh = {
          enable = true;
          settings.PasswordAuthentication = false;
          settings.PermitRootLogin = "no"; # Optional: disable root login
        };
        networking.firewall.enable = false;

        microvm.shares = [
          {
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
            tag = "ro-store";
            proto = "virtiofs";
          }

          {
            # On the host
            source = "/var/lib/microvms/${hostName}/journal";
            # In the MicroVM
            mountPoint = "/var/log/journal";
            tag = "journal";
            proto = "virtiofs";
            socket = "journal.sock";
          }
        ];
        services.scrutiny = {
          enable = true;
          openFirewall = false;
          settings.web.listen.port = 6464;
        };
      };
    };
  };
}
