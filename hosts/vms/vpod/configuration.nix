{ hostName, ... }:
{
  services.vpod = {
    enable = true;
    settings = {
      baseUrl = "https://podcasts.ajax.lol";
      frontend.passwordFile = "/run/agenix/vpod/passwordfile";
      port = 4119;
    };
  };

  environment.etc."machine-id" = {
    mode = "0644";
    text = "b7a4f2c83e914e1ebc3a4a2e8e9d5f01" + "\n";
  };

  networking = {
    inherit hostName;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        4119
      ];
    };
  };

  # services.openssh = {
  #   enable = true;
  #   settings.PasswordAuthentication = true;
  # };
  # users = {
  #   mutableUsers = true;
  #   users.admin = {
  #     isNormalUser = true;
  #     extraGroups = [ "wheel" ];
  #     initialPassword = "pleasehackme";
  #   };
  # };

  systemd.network = {
    enable = true;
    networks."20-lan" = {
      matchConfig.Type = "ether";
      networkConfig = {
        Address = [ "172.22.2.51/15" ];
        Gateway = "172.22.0.1";
        DNS = [ "172.22.0.1" ];
        IPv6AcceptRA = true;
        DHCP = "no";
      };
    };
  };

  age.secrets."vpod/passwordfile" = {
    file = ../../../secrets/vpod/passwordfile.age;
    mode = "440";
    owner = "vpod";
    group = "vpod";
  };
  age.identityPaths = [ "/identities/ssh_host_ed25519_key" ];
  fileSystems."/identities".neededForBoot = true;

  microvm = {
    interfaces = [
      {
        type = "tap";
        id = "vm-${hostName}";
        mac = "02:00:00:00:00:01";
      }
    ];
    shares = [
      {
        # on host
        source = "/nix/store";
        # on guest
        mountPoint = "/nix/.ro-store";
        tag = "ro-store";
        proto = "virtiofs";
      }
      {
        # on host
        source = "/etc/ssh";
        # on guest
        mountPoint = "/identities";
        tag = "identities";
        proto = "virtiofs";
        readOnly = true;
        socket = "identities.socket";
      }
    ];
    volumes = [
      {
        # on host
        image = "/var/lib/microvms/vpod/data.img";
        # on guest
        mountPoint = "/var/lib/vpod";
        size = 4096; # 4 Gib
      }
    ];
  };
}
