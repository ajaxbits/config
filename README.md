[![built with garnix](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fajaxbits%2Fconfig%3Fbranch%3Dmain)](https://garnix.io)

# my config

WIP nixos infrastructure.

## Patroclus memory

`hosts/patroclus/disks/boot.nix` caps the ZFS ARC at 24 GiB and sets
`vm.swappiness` to 20, leaving room for the two 6 GiB microVMs and host
services while retaining encrypted disk swap. After a reboot, check
`/sys/module/zfs/parameters/zfs_arc_max` and `sysctl vm.swappiness`; use
memory pressure, swap I/O, and ARC hit rate under load before retuning.
These settings do not immediately empty already-used swap.

## Patroclus metrics

VictoriaMetrics scrapes the blackbox, node, and NUT exporters, plus the
separately configured UniFi poller.

The node exporter textfile collector publishes `system_version` as the numeric
system-profile generation on boot and activation. To mark deployments on an
existing Grafana dashboard, add an annotation using the
`Prometheus (VictoriaMetrics)` datasource with the query
`changes(system_version{host="patroclus"}[5m]) > 0` and show it on all panels.
Annotations are dashboard-scoped; this repo does not manage dashboards.

## Patroclus audit

The 64-bit `execve` audit rule remains enabled. The audit backlog is 8192
at boot and when rules load. After reboot, check `sudo auditctl -s` for
`backlog_limit 8192` and watch whether `lost` increases under load. A larger
backlog absorbs bursts, not sustained overload; if events are still lost,
investigate auditd throughput and the broad `execve` rule.

## Umami (components/umami)

Two ways in, nothing else:

- **Public tracker** `analytics-grace.ajax.lol` → Cloudflare Tunnel → guest
  HAProxy `192.168.85.2:8080` → Umami. Only `GET/HEAD /script.js` and
  `POST/OPTIONS /api/send` (Origin `gracebobber.com`/`www`) get through.
- **Private dashboard** `analytics-grace.ajax.casa` → host Caddy → Umami
  `192.168.85.2:3000`, only from `172.22.0.0/16` and Tailscale.

The guest has no Internet, shares, vsock or SSH. Host table `inet umami`
allows only cloudflared → :8080, Caddy → :3000, and guest → host bouncer
`192.168.85.1:9000`. HAProxy asks that bouncer about each visitor IP
(CrowdSec Community Blocklist Lite, nothing shared back); anything but
`allow` is 403, no answer is 503. The bouncer does not wait for its first
feed sync, so 503 means "bouncer down", not "feed stale".

First activation (DNS for the public name still absent):

```sh
sudo cscli capi status
sudo install -d -m 0700 /var/lib/umami-crowdsec
sudo sh -c 'umask 077; cscli bouncers add umami-spoa -o raw > /var/lib/umami-crowdsec/api-key'
sudo systemctl start umami-spoa
sudo cscli decisions list --origin CAPI | head   # must show community decisions
```

Then log into the dashboard (fresh DB: `admin`/`umami`, change it at once),
add the website in the UI (its ID goes in gracebobber's `Base.astro`), and
only then add the proxied CNAME `analytics-grace.ajax.lol` → `<tunnel id>.cfargotunnel.com`.

- Stop everything: `sudo systemctl stop umami-firewall` (guest and bouncer stop first).
- Roll back public exposure: delete the CNAME/ingress; keep
  `/var/lib/microvms/umami/umami-var.img` (data + secret).
- Network test: `sudo $(nix build --no-link --print-out-paths .#nixosConfigurations.patroclus.config.system.build.umamiNetworkTest)/bin/check-umami-network`
