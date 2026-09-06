# Grace's isolated website editor

The VM is installed declaratively but started manually:

```sh
sudo systemctl start microvm@grace-editor
sudo journalctl -fu microvm@grace-editor
```

Deploy the host configuration first. Starting the VM also requests its
installation unit and the `grace-editor-firewall` unit. It does not autostart.
Guest services start inside the VM, not on the host.

- Editor: `http://172.22.0.10:4096`
- Preview: `http://172.22.0.10:4321`
- Guest: `192.168.83.2/24`, gateway `192.168.83.1`
- Host bridge: `agentbr0`, containing only the `agent-grace` tap.

## Network ownership

This component does **not** enable the NixOS global nftables/NAT services or
change the host's existing `br0` address, default gateway, or DNS. In particular,
the global nftables service would default to flushing the entire ruleset with
this host's `system.stateVersion = "23.05"`, destroying Docker, Kubernetes and
Tailscale rules.

`grace-editor-firewall` uses the nft binary directly to manage only the
`inet grace_editor` table. Creation and reload atomically replace that table;
cleanup removes only that table. There is no global ruleset flush or iptables
kernel-module blacklist. All filtering is scoped to traffic entering/leaving
`agentbr0`; unrelated traffic continues through the existing owners' policies.

New LAN connections must originate in `172.22.0.0/15`, arrive on `br0`, and target
`172.22.0.10` on one of the two forwarded ports. Direct routed guest access is
blocked. Host-initiated administration and replies to allowed connections work.
New guest connections can leave only through `br0` toward public IPv4 addresses;
host services, private/link-local/multicast destinations and the Tailscale CGNAT
range are blocked. Guest IPv6 and source-address spoofing are dropped by the
host. The host does not accept DHCP or IPv6 router advertisements on the guest
bridge/tap, so the guest cannot supply a replacement host default route.

The VM has `BindsTo=` and `After=` dependencies on its firewall: a failed startup
prevents VM startup, and stopping the firewall stops the VM before removing the
rules. Reload uses an atomic nft transaction, preserving established connections
and the previous policy if a new ruleset is invalid.

The current host's shared IPv4 FORWARD chain has policy ACCEPT. Our table's
ACCEPT verdicts do not bypass other owners' later DROP rules; if the host's
forwarding policy changes, re-test connectivity rather than overriding those
owners' rules globally.

## Verification without touching the live network

The test uses the **generated deployment rules**, inside new network, mount,
and PID namespaces. It creates a synthetic host, guest, LAN, upstream router,
and VPN peer. All test IPs, including the public-looking addresses, remain in
these namespaces. It requires root for namespace setup, not for live changes.

With the default network options:

```sh
test_package=$(nix build --no-link --print-out-paths \
  .#nixosConfigurations.patroclus.config.system.build.graceEditorNetworkTest)
sudo "$test_package/bin/check-grace-editor-network"
```

Checks cover TCP/UDP replies, SNAT, both LAN forwards, host/LAN/VPN isolation,
IPv6 and spoofing, unrelated host/transit traffic, rule-owner preservation,
live connections across reload, a rejected invalid reload, and idempotent cleanup.

Before deployment, also evaluate/build the intended host configuration. The
component's focused checks do not replace checks for unrelated host modules.
After deployment, confirm existing container/cluster/tailnet services remain
reachable before starting the editor. A failed editor startup can be diagnosed
with `systemctl status grace-editor-firewall microvm@grace-editor`.
