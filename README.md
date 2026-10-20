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
