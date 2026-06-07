{ config, ... }:
let
  mainIp = "172.22.0.10";
  mainBridge = "br0";
in
{
  age.secrets."k3s/common-secret".file = ../../secrets/k3s/common-secret.age;

  # Route *.k.ajax.casa → traefik. New services only need a kubectl ingress
  # rule; no Nix rebuild required.
  services.caddy.virtualHosts."https://*.k.ajax.casa".extraConfig = ''
    import cloudflare
    reverse_proxy http://127.0.0.1:30080
  '';

  services.k3s = {
    enable = true;
    role = "server";
    clusterInit = true;
    tokenFile = config.age.secrets."k3s/common-secret".path;

    # Pin flannel to the bridge defined in hypervisor.nix. Without these,
    # flannel picks the default-route iface and may grab tailscale0 or a
    # docker bridge, clobbering routes (k3s-io/k3s#12459).
    nodeIP = mainIp;
    extraFlags = [
      "--flannel-iface=${mainBridge}"
      "--tls-san=${mainIp}"
    ];

    # Drain pods before reboot; system.autoUpgrade reboots nightly.
    gracefulNodeShutdown.enable = true;

    # Pin traefik to fixed NodePorts so cloudflared can route to a stable
    # address without binding to host port 80/443.
    manifests.traefik-config.content = {
      apiVersion = "helm.cattle.io/v1";
      kind = "HelmChartConfig";
      metadata = {
        name = "traefik";
        namespace = "kube-system";
      };
      spec.valuesContent = ''
        service:
          type: NodePort
        ports:
          web:
            nodePort: 30080
          websecure:
            nodePort: 30443
      '';
    };
  };
}
