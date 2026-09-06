# networkd / Tailscale routing regression

Run from the repository root:

```sh
nix build --no-link --print-build-logs \
  .#nixosConfigurations.patroclusStripped.config.system.build.networkdRoutingPolicyTest
```

This is a NixOS VM test, separate from the editor firewall's namespace test.
It requires a Linux builder with KVM/NixOS-test support. It boots an isolated
guest, runs the pinned systemd-networkd with the host's actual global settings,
and installs Tailscale-style IPv4 and IPv6 policy rules.

It verifies that those rules survive:

- a networkd restart;
- a managed-link reconfiguration;
- adding an editor bridge and restarting networkd.

The negative control switches the guest to the previous `yes` default and
verifies that networkd really deletes the rules. Restoring the production
configuration must preserve them again. All restarts and configuration changes
occur in the disposable test VM, not on the machine running the test.

This covers the routing-rule deletion observed during the September 6 deployment.
It does not emulate Tailscale's NextDNS-over-HTTPS connections or prove the entire
DNS interruption was caused solely by rule deletion. In particular, temporary
IPv6 address changes during activation remain a separate possible contributor.
