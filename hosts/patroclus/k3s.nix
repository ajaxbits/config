{ config, ... }:
let
  mainIp = "172.22.0.10";
  mainBridge = "br0";
in
{
  age.secrets."k3s/common-secret".file = ../../secrets/k3s/common-secret.age;

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.age.secrets."k3s/common-secret".path;
    disable = [ "traefik" ];

    # Pin flannel to the bridge defined in hypervisor.nix. Without these,
    # flannel picks the default-route iface and may grab tailscale0 or a
    # docker bridge, clobbering routes (k3s-io/k3s#12459).
    nodeIP = mainIp;
    extraFlags = [ "--flannel-iface=${mainBridge}" ];

    # Drain pods before reboot; system.autoUpgrade reboots nightly.
    gracefulNodeShutdown.enable = true;
  };
}
