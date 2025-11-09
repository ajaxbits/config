let
  ethernetIface = "eno2"; # this is what the iface is named in the system
  bridgeIface = "br0"; # created by this file

  routerIP = "172.22.0.1";
  v4CIDR = "172.22.0.10/15"; # the static ip, followe by the whole range
in
{
  networking.useNetworkd = true;
  systemd.network = {
    enable = true;
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
}
