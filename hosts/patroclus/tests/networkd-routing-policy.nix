# A real networkd restart test in a disposable NixOS VM. The production setting
# is passed in by hypervisor.nix; no network service on the test host is touched.
{ pkgs, networkConfig }:
pkgs.testers.runNixOSTest {
  name = "patroclus-networkd-routing-policy";

  nodes.machine = {
    virtualisation.memorySize = 512;
    networking.useNetworkd = true;
    systemd.network = {
      config.networkConfig = networkConfig;
      netdevs."10-dummy0".netdevConfig = {
        Name = "dummy0";
        Kind = "dummy";
      };
      networks."10-dummy0" = {
        matchConfig.Name = "dummy0";
        address = [ "192.0.2.1/24" ];
        networkConfig.ConfigureWithoutCarrier = true;
        linkConfig.RequiredForOnline = "no";
      };
    };
  };

  testScript = ''
    import json

    start_all()
    machine.wait_for_unit("systemd-networkd.service")

    def wait_configured(interface):
        machine.wait_until_succeeds(
            f"networkctl status {interface} --no-pager | grep -F '(configured)'"
        )

    def add_rules():
        for family in ("-4", "-6"):
            for rule in (
                "pref 5210 fwmark 0x80000/0xff0000 lookup main",
                "pref 5230 fwmark 0x80000/0xff0000 lookup default",
                "pref 5250 fwmark 0x80000/0xff0000 unreachable",
                "pref 5270 lookup 52",
            ):
                machine.succeed(f"ip {family} rule add {rule}")

    def rules():
        return {
            family: json.loads(machine.succeed(f"ip {family} -j rule show"))
            for family in ("-4", "-6")
        }

    wait_configured("dummy0")
    add_rules()
    expected = rules()

    with subtest("foreign IPv4 and IPv6 rules survive networkd restart"):
        machine.succeed("systemctl restart systemd-networkd")
        machine.wait_for_unit("systemd-networkd.service")
        wait_configured("dummy0")
        assert rules() == expected

    with subtest("foreign rules survive reconfiguration"):
        machine.succeed("networkctl reconfigure dummy0")
        wait_configured("dummy0")
        assert rules() == expected

    with subtest("adding the editor bridge preserves foreign rules"):
        machine.succeed("mkdir -p /run/systemd/network")
        machine.succeed("printf '[NetDev]\\nName=agentbr0\\nKind=bridge\\n' > /run/systemd/network/30-agentbr0.netdev")
        machine.succeed("printf '[Match]\\nName=agentbr0\\n[Network]\\nAddress=192.168.83.1/24\\nConfigureWithoutCarrier=yes\\nDHCP=no\\nIPv6AcceptRA=no\\nLinkLocalAddressing=no\\n' > /run/systemd/network/30-agentbr0.network")
        machine.succeed("systemctl restart systemd-networkd")
        machine.wait_for_unit("systemd-networkd.service")
        wait_configured("agentbr0")
        machine.succeed("ip -4 address show agentbr0 | grep -F 192.168.83.1/24")
        assert rules() == expected

    with subtest("negative control reproduces deletion with the old default"):
        # This makes the test sensitive to the original bug, rather than just
        # checking that an option evaluates. It runs only inside this test VM.
        machine.succeed("mkdir -p /run/systemd/networkd.conf.d")
        machine.succeed("printf '[Network]\\nManageForeignRoutingPolicyRules=yes\\n' > /run/systemd/networkd.conf.d/99-control.conf")
        machine.succeed("systemctl restart systemd-networkd")
        machine.wait_for_unit("systemd-networkd.service")
        wait_configured("dummy0")
        for family in ("-4", "-6"):
            machine.wait_until_succeeds(f"! ip {family} rule show | grep -E '^52(10|30|50|70):'")
        assert rules() != expected

    with subtest("restoring production configuration preserves rules again"):
        machine.succeed("rm /run/systemd/networkd.conf.d/99-control.conf")
        add_rules()
        machine.succeed("systemctl restart systemd-networkd")
        machine.wait_for_unit("systemd-networkd.service")
        wait_configured("dummy0")
        assert rules() == expected
  '';
}
