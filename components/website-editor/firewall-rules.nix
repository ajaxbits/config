{ cfg }:
''
  # Atomic replacement of our table only, including on first installation.
  table inet grace_editor;
  delete table inet grace_editor;
  table inet grace_editor {
    set non_public_v4 {
      type ipv4_addr;
      flags interval;
      elements = {
        0.0.0.0/8, 10.0.0.0/8, 100.64.0.0/10, 127.0.0.0/8,
        169.254.0.0/16, 172.16.0.0/12, 192.0.0.0/24, 192.0.2.0/24,
        192.168.0.0/16, 198.18.0.0/15, 198.51.100.0/24, 203.0.113.0/24,
        224.0.0.0/4, 240.0.0.0/4
      };
    }

    chain input {
      type filter hook input priority filter - 10; policy accept;
      iifname "agentbr0" jump from_guest_to_host
    }

    chain from_guest_to_host {
      meta nfproto != ipv4 counter drop
      ip saddr != ${cfg.vm.ip} counter drop
      ct state invalid counter drop
      # Permit responses to host-initiated administration, never new guest
      # connections to ANY host address (including public and tailnet IPs).
      ct state established,related counter accept
      counter drop
    }

    chain forward {
      type filter hook forward priority filter - 10; policy accept;
      iifname "agentbr0" jump from_guest
      oifname "agentbr0" jump to_guest
    }

    chain from_guest {
      meta nfproto != ipv4 counter drop
      ip saddr != ${cfg.vm.ip} counter drop
      ct state invalid counter drop
      # Even a public destination must leave via the LAN gateway, not a VPN
      # or another VM/container interface. This also constrains reply traffic.
      oifname != "${cfg.lan.interface}" counter drop
      ct state established,related counter accept
      ip daddr @non_public_v4 counter drop
      counter accept
    }

    chain to_guest {
      meta nfproto != ipv4 counter drop
      ip daddr != ${cfg.vm.ip} counter drop
      ct state invalid counter drop
      iifname != "${cfg.lan.interface}" counter drop
      ct state established,related counter accept
      # Only connections actually DNATed from the intended LAN address and
      # subnet may open the UI. Direct routed access to the guest is denied.
      ip saddr ${cfg.lan.cidr} ct status dnat ct original ip daddr ${cfg.lan.hostIP} tcp dport { ${toString cfg.editorPort}, ${toString cfg.previewPort} } counter accept
      counter drop
    }

    chain prerouting {
      type nat hook prerouting priority dstnat - 10; policy accept;
      iifname "${cfg.lan.interface}" ip saddr ${cfg.lan.cidr} ip daddr ${cfg.lan.hostIP} tcp dport ${toString cfg.editorPort} counter dnat ip to ${cfg.vm.ip}:${toString cfg.editorPort}
      iifname "${cfg.lan.interface}" ip saddr ${cfg.lan.cidr} ip daddr ${cfg.lan.hostIP} tcp dport ${toString cfg.previewPort} counter dnat ip to ${cfg.vm.ip}:${toString cfg.previewPort}
    }

    chain postrouting {
      type nat hook postrouting priority srcnat + 10; policy accept;
      iifname "agentbr0" oifname "${cfg.lan.interface}" ip saddr ${cfg.vm.ip} counter masquerade
    }
  }
''
