# LAN/Tailscale only like ntfy; not routed by the Cloudflare tunnel. No auth.
{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  url = "https://apartments.${config.networking.domain}";
in
{
  services.caddy.virtualHosts.${url} = mkIf config.components.caddy.enable {
    extraConfig = ''
      import cloudflare
      reverse_proxy http://127.0.0.1:8791
    '';
  };
}
