{ config, lib, ... }:
let
  cfg = config.components.website-editor;
  bridge = "agentbr0";
in
{
  config = lib.mkIf cfg.enable {
    # This is deliberately separate from br0.  The guest has Internet access
    # through NAT but cannot initiate connections to the homelab or its LAN.
    systemd.network = {
      netdevs."30-${bridge}".netdevConfig = {
        Name = bridge;
        Kind = "bridge";
      };
      networks = {
        "30-${bridge}" = {
          matchConfig.Name = bridge;
          address = [ "${cfg.vm.gateway}/${toString cfg.vm.cidr}" ];
          networkConfig.ConfigureWithoutCarrier = true;
        };
        "31-agent-grace" = {
          matchConfig.Name = "agent-grace";
          networkConfig.Bridge = bridge;
        };
      };
    };

    networking = {
      nat = {
        enable = true;
        internalInterfaces = [ bridge ];
        externalInterface = "br0";
        forwardPorts = [
          {
            sourcePort = cfg.editorPort;
            destination = "${cfg.vm.ip}:${toString cfg.editorPort}";
            proto = "tcp";
          }
          {
            sourcePort = cfg.previewPort;
            destination = "${cfg.vm.ip}:${toString cfg.previewPort}";
            proto = "tcp";
          }
        ];
      };
      nftables.enable = true;
      nftables.tables.agent-isolation = {
        family = "inet";
        content = ''
          chain forward {
            type filter hook forward priority filter - 1; policy accept;

            # Do not let this autonomous guest reach the host, LAN, tailnet,
            # Kubernetes ranges, or RFC1918 destinations.
            iifname "${bridge}" ip daddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } drop
            iifname "${bridge}" ip6 daddr { ::1/128, fc00::/7, fe80::/10 } drop

            # Only the two explicitly forwarded services are reachable from
            # the LAN. Replies to guest-originated Internet traffic continue
            # to work through the normal connection tracker.
            iifname "br0" oifname "${bridge}" ip daddr ${cfg.vm.ip} tcp dport { ${toString cfg.editorPort}, ${toString cfg.previewPort} } accept
            iifname "br0" oifname "${bridge}" drop
          }
        '';
      };
    };
  };
}
