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
