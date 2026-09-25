{ net, proxyUid }:
''
  # Atomic replacement of our table only, including on first installation.
  table inet paperless;
  delete table inet paperless;
  table inet paperless {
    chain input {
      type filter hook input priority filter - 10; policy accept;
      iifname "${net.bridge}" jump from_guest
    }

    # The guest never opens connections, not even to host services: only
    # replies to connections the reverse proxy opened are accepted.
    chain from_guest {
      meta nfproto != ipv4 counter drop
      ip saddr != ${net.ip} counter drop
      ct state established,related counter accept
      counter drop
    }

    chain output {
      type filter hook output priority filter - 10; policy accept;
      oifname "${net.bridge}" jump to_guest
    }

    # Only the reverse proxy's user may connect, and only to the web port.
    # Other host services, containers with host networking, etc. may not.
    chain to_guest {
      meta nfproto != ipv4 counter drop
      ip daddr != ${net.ip} counter drop
      ct state established,related counter accept
      ct state new meta skuid ${toString proxyUid} tcp dport ${toString net.port} counter accept
      counter drop
    }

    # Nothing is routed to or from the guest: no LAN, VPN, container or VM peers.
    chain forward {
      type filter hook forward priority filter - 10; policy accept;
      iifname "${net.bridge}" counter drop
      oifname "${net.bridge}" counter drop
    }
  }
''
