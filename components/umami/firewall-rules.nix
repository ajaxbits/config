{ net, cloudflaredUid, caddyUid }:
let
  inherit (net) bridge gateway ip;
  collector = toString net.collectorPort;
  app = toString net.port;
  spoa = toString net.spoaPort;
in
''
  # Atomic replacement of our table only, including on first installation.
  table inet umami;
  delete table inet umami;
  table inet umami {
    chain input {
      type filter hook input priority filter - 10; policy accept;

      # Private dashboard clients can't be impersonated by containers/VMs.
      tcp dport 443 ip saddr 172.22.0.0/16 iifname != { "br0", "tailscale0", "lo" } counter drop
      tcp dport 443 ip saddr 100.64.0.0/10 iifname != { "tailscale0", "lo" } counter drop
      tcp dport 443 ip6 saddr fd7a:115c:a1e0::/48 iifname != { "tailscale0", "lo" } counter drop

      # The bouncer is only for the guest.
      ip daddr ${gateway} tcp dport ${spoa} iifname != "${bridge}" counter drop
      iifname "${bridge}" jump from_guest
    }

    chain from_guest {
      meta nfproto != ipv4 counter drop
      ip saddr != ${ip} counter drop
      ip daddr != ${gateway} counter drop
      # Replies to the tunnel/Caddy connections.
      tcp sport { ${collector}, ${app} } ct state established ct direction reply counter accept
      # The only connection the guest may open: CrowdSec IP lookups.
      tcp dport ${spoa} ct state { new, established } ct direction original counter accept
      counter drop
    }

    chain output {
      type filter hook output priority filter - 10; policy accept;
      oifname "${bridge}" jump to_guest
    }

    chain to_guest {
      meta nfproto != ipv4 counter drop
      ip saddr != ${gateway} counter drop
      ip daddr != ${ip} counter drop
      # Only cloudflared may reach HAProxy, only Caddy may reach Umami.
      ct state new meta skuid ${toString cloudflaredUid} tcp dport ${collector} counter accept
      ct state new meta skuid ${toString caddyUid} tcp dport ${app} counter accept
      # Conntrack entries only exist for flows accepted above.
      ct state established ct direction original tcp dport { ${collector}, ${app} } counter accept
      tcp sport ${spoa} ct state established ct direction reply counter accept
      counter drop
    }

    # Nothing is routed to or from the guest.
    chain forward {
      type filter hook forward priority filter - 10; policy accept;
      iifname "${bridge}" counter drop
      oifname "${bridge}" counter drop
    }
  }
''
