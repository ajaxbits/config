{inputs, ...}: {
  imports = [
    inputs.agenix.nixosModules.age
    ./dns
    ./miniflux
    ./mediacenter
    ./tailscale
    ./zfs
  ];
}
