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

## Guest access and first boot

From the homelab's `admin` account:

```sh
ssh grace-editor
```

The host alias uses `~/.ssh/grace-editor`; its public key is declared in
`components.website-editor.authorizedKeys`. The private key stays on the host.
Guest SSH accepts key authentication from the bridge gateway only; port 22 is
not forwarded from the LAN. From another device, SSH into patroclus first.
The guest has passwordless sudo. Its own SSH host key persists on the home
volume, so rebuilding/rebooting it does not change the server identity.

The private website repository requires a guest-specific GitHub deploy key.
Before the initial clone, create one **inside the guest**:

```sh
install -d -m 700 ~/.ssh
ssh-keygen -t ed25519 -N '' -C grace-editor -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub
```

Add that public key to `ajaxbits/gracebobber` → Settings → Deploy keys, enabling
write access for publishing. Keep the private half inside the guest. The
bootstrap uses SSH transport and a pinned GitHub host key; it never receives
the administrator's broad GitHub token. Bootstrap initially fails until this
deploy key is provisioned; guest SSH remains available independently.
Deploy keys authenticate Git operations only. Watching private Actions runs
with `gh` additionally requires a repository-scoped token with Actions read
access; Copilot authentication is not a substitute for that permission.

Then run **inside the guest**:

```sh
sudo systemctl restart grace-editor-bootstrap
sudo systemctl start opencode2-grace-editor grace-editor-preview
sudo systemctl status grace-editor-bootstrap opencode2-grace-editor grace-editor-preview
```

For bootstrap errors, use `sudo journalctl -u grace-editor-bootstrap -b` in
the guest. Its home filesystem is explicitly mounted before boot activation,
then tmpfiles sets the volume root's ownership to `agent:users`. Dependency
installation is stamped only after `npm ci` succeeds and repeated after a
lockfile/Node version change or incomplete install.

OpenCode's generated server password is available to the guest administrator
in `sudo journalctl -u opencode2-grace-editor -b`. Use it to connect the web UI,
then connect GitHub Copilot there. That OAuth connection and the repository
deploy key serve separate purposes. Both OpenCode state and the checkout are
on `/home/agent` and survive a VM restart.

`just dev` checks the preview over guest loopback, while reporting the LAN URL
to Grace. The agent is deliberately unable to connect to that host URL itself.

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
