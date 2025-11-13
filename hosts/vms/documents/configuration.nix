{ hostName, ... }:
let
  ipAddress = "172.22.2.52";
in
{
  imports = [
    ./paperless.nix
  ];

  microvm = {
    mem = 2048;
    interfaces = [
      {
        type = "tap";
        id = "vm-${hostName}";
        mac = "02:00:00:00:00:02";
      }
    ];
    shares = [
      {
        source = "/nix/store";
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }

      # {
      #   # On the host
      #   source = "/var/lib/microvms/${hostName}/journal";
      #   # In the MicroVM
      #   mountPoint = "/var/log/journal";
      #   tag = "journal";
      #   proto = "virtiofs";
      #   socket = "journal.sock";
      # }
    ];
  };

  environment.etc."machine-id" = {
    mode = "0644";
    text = "2cfdf6c7cdba4ce1a9f45efaa8cfc740" + "\n";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  networking = {
    inherit hostName;
    firewall.enable = false;
  };

  users = {
    mutableUsers = true;
    users.admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "pleasehackme";
    };
  };

  systemd.network = {
    enable = true;
    networks."20-lan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        Address = [ "${ipAddress}/15" ];
        Gateway = "172.22.0.1";
        DNS = [ "172.22.0.1" ];
        IPv6AcceptRA = true;
        DHCP = "no";
      };
    };
  };

}
