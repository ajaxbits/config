{ config, pkgs, ... }:
let
  ethernetIface = "eno2"; # this is what the iface is named in the system
  bridgeIface = "br0"; # created by this file

  routerIP = "172.22.0.1";
  v4CIDR = "172.22.0.10/15"; # the static ip, followe by the whole range
in
{

  systemd.tmpfiles.rules = map (
    vmHost:
    let
      machineId = "b7a4f2c83e914e1ebc3a4a2e8e9d5f01";
    in
    # creates a symlink of each MicroVM's journal under the host's /var/log/journal
    "L+ /var/log/journal/${machineId} - - - - /var/lib/microvms/${vmHost}/journal/${machineId}"
  ) [ "test1" ];

  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
    # Tailscale owns policy rules 5210-5270. networkd otherwise removes them
    # when it starts/reconfigures links, which can interrupt tailnet routing
    # and the host's MagicDNS path. Leave rules owned by other services alone.
    config.networkConfig.ManageForeignRoutingPolicyRules = false;
    netdevs.${bridgeIface}.netdevConfig = {
      Name = bridgeIface;
      Kind = "bridge";
    };
    networks = {
      "10-lan" = {
        matchConfig.Name = [
          ethernetIface
          "vm-*"
        ];
        networkConfig.Bridge = bridgeIface;
      };
      "10-lan-bridge" = {
        matchConfig.Name = bridgeIface;
        networkConfig = {
          Address = [
            v4CIDR
            # "2001:db8::a/64" TODO
          ];
          Gateway = routerIP;
          DNS = [ routerIP ];
          # IPv6AcceptRA = true; TODO
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
  };

  system.build.networkdRoutingPolicyTest = import ./tests/networkd-routing-policy.nix {
    inherit pkgs;
    networkConfig = config.systemd.network.config.networkConfig;
  };
}
