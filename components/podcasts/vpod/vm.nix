{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:
let
  inherit (lib) mkMerge;

  hostName = "vpod"; # changes several things here, so be cautious
  cfg = config.components.podcasts.vpod;

  _gatewayParts = lib.splitString "/" cfg.vm.gatewayCIDR;

  gateway = lib.elemAt _gatewayParts 0;
  CIDR = lib.elemAt _gatewayParts 1;

  nodeExporterPort = 9002;
in
{
  ### HOST CONFIG ###
  config = lib.mkIf cfg.enable {
    services.victoriametrics.prometheusConfig.scrape_configs = [
      {
        job_name = "node-exporter-${hostName}";
        scrape_interval = "30s";
        metrics_path = "/metrics";
        static_configs = [
          {
            targets = [ "${cfg.vm.ip}:${builtins.toString nodeExporterPort}" ];
            labels.type = "node";
            labels.host = hostName;
          }
        ];
      }
    ];

    microvm.vms.${hostName} = {
      inherit pkgs;

      specialArgs = {
        inherit (pkgs) lib;
      };

      extraModules = [
        inputs.agenix.nixosModules.age
        inputs.vpod.nixosModules.default
      ];

      ### GUEST CONFIG ###
      config =
        let
          hostConfig = config;
        in
        mkMerge [
          (import ./service.nix { config = hostConfig; })
          {
            environment.etc."machine-id" = {
              mode = "0644";
              text = "b7a4f2c83e914e1ebc3a4a2e8e9d5f01" + "\n";
            };

            systemd.network = {
              enable = true;
              networks."20-lan" = {
                matchConfig.Type = "ether";
                networkConfig = {
                  Address = [ "${cfg.vm.ip}/${CIDR}" ];
                  Gateway = gateway;
                  DNS = [ gateway ];
                  IPv6AcceptRA = true;
                  DHCP = "no";
                };
              };
            };
            networking = {
              inherit hostName;
              firewall = {
                enable = true;
                allowedTCPPorts = [
                  cfg.port
                  nodeExporterPort
                ];
              };
            };

            services.prometheus.exporters.node = {
              enable = true;
              port = nodeExporterPort;
              enabledCollectors = [
                "ethtool"
                "interrupts"
                "processes"
                "softirqs"
                "systemd"
                "tcpstat"
              ];
            };

            fileSystems = {
              "/identities".neededForBoot = true;
              "/var/lib/vpod".neededForBoot = true;
            };
            age.identityPaths = [ "/identities/ssh_host_ed25519_key" ];

            microvm = {
              hypervisor = "cloud-hypervisor";
              vsock.cid = 8; # arbitrary, honestly
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
        ];
    };
  };
}
