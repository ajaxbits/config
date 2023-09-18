{inputs, ...}: {
  imports = [
    inputs.agenix.nixosModules.age
    ./dns
    ./miniflux
    ./tailscale
    ./zfs
  ];
}
