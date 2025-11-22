{ hostName, lib, ... }:
rec {
  imports = [
    # Be careful here
    # ./debugging.nix
  ];

  services.vpod = {
    enable = true;
    settings = {
      baseUrl = "https://podcasts.ajax.lol";
      frontend.passwordFile = "/run/agenix/vpod/passwordfile";
      port = 4119;
      monitoring.victoriaLogsEndpoint = "http://172.22.0.10:9428";
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

  fileSystems = lib.genAttrs (map (share: share.mountPoint) microvm.shares) (_: {
    neededForBoot = true;
  });

  microvm = {
    hypervisor = "cloud-hypervisor";
    hotplugMem = 1536;
    interfaces = [
      {
        type = "tap";
        id = "vm-${
          if builtins.stringLength hostName <= 8 then
            hostName
          else
            builtins.substring (builtins.stringLength hostName - 8) 8 hostName
        }";
        mac =
          let
            hash = builtins.hashString "sha256" hostName;
            octets = lib.genList (i: builtins.substring (i * 2) 2 hash) 5;
          in
          "02:${lib.concatStringsSep ":" octets}";
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
