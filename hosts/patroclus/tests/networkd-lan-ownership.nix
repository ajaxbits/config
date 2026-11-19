# Exercise the production ownership policy without touching the host network.
{ pkgs, unmanaged, netdevs, networks }:
pkgs.testers.runNixOSTest {
  name = "patroclus-networkd-lan-ownership";

  nodes.machine = {
    virtualisation.memorySize = 768;
    virtualisation.vlans = [ ];
    networking = {
      useDHCP = false;
      useNetworkd = true;
      networkmanager = {
        enable = true;
        inherit unmanaged;
        settings.main.no-auto-default = "*";
        ensureProfiles.profiles.eno2-dhcp = {
          connection = {
            id = "eno2-dhcp";
            type = "ethernet";
            interface-name = "eno2";
            autoconnect = true;
          };
          ipv4.method = "auto";
          ipv6.method = "disabled";
        };
      };
    };
    systemd.network = {
      inherit networks;
      netdevs = netdevs // {
        "10-test-lan" = {
          netdevConfig = {
            Name = "eno2";
            Kind = "veth";
          };
          peerConfig.Name = "lan-peer";
        };
      };
      wait-online.enable = false;
    };
    environment.systemPackages = [ pkgs.dnsmasq ];
  };

  testScript = ''
    import json

    start_all()
    machine.wait_for_unit("systemd-networkd.service")
    machine.wait_for_unit("NetworkManager.service")
    machine.wait_until_succeeds("nmcli connection show eno2-dhcp")
    machine.wait_until_succeeds("ip link show lan-peer")
    machine.succeed(
        "ip netns add router",
        "ip link set lan-peer netns router",
        "ip -n router link set lo up",
        "ip -n router link set lan-peer up",
        "ip -n router address add 172.22.0.1/16 dev lan-peer",
        "ip netns exec router dnsmasq --conf-file=/dev/null --port=0 "
        "--interface=lan-peer --bind-interfaces "
        "--dhcp-range=172.22.0.10,172.22.0.10,255.255.0.0,1h "
        "--dhcp-option=3,172.22.0.1 --pid-file=/run/test-dhcp.pid "
        "--dhcp-leasefile=/run/test-dhcp.leases",
    )

    def assert_lan():
        for interface in ("eno2", "br0"):
            machine.wait_until_succeeds(
                f"test $(nmcli -g GENERAL.NM-MANAGED device show {interface}) = no"
            )
        machine.wait_until_succeeds("ping -n -c 1 -W 2 172.22.0.1")
        addresses = json.loads(machine.succeed("ip -j -4 address show dev eno2"))
        assert not any(link["addr_info"] for link in addresses), addresses
        route = json.loads(machine.succeed("ip -j route get 172.22.0.1"))[0]
        assert route["dev"] == "br0", route
        assert route["prefsrc"] == "172.22.0.10", route

    with subtest("stale autoconnect DHCP profile cannot claim the LAN port"):
        assert_lan()
        machine.fail("nmcli --wait 10 connection up eno2-dhcp")
        assert_lan()

    for service in ("NetworkManager", "systemd-networkd"):
        with subtest(f"bridge reachability survives {service} restart"):
            machine.succeed(f"systemctl restart {service}")
            machine.wait_for_unit(f"{service}.service")
            assert_lan()
  '';
}
