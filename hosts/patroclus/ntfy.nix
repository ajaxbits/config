{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkIf;

  port = 2586;
  url = "https://ntfy.${config.networking.domain}";
in
{
  # LAN-only push notifications: *.ajax.casa resolves to patroclus on the LAN
  # (Tailscale subnet routing covers remote clients), and the Cloudflare tunnel
  # does not route this host. No auth: anyone on the LAN can publish/subscribe.
  services.ntfy-sh = {
    enable = true;
    settings = {
      base-url = url;
      # Loopback only; Caddy terminates TLS in front of it.
      listen-http = "127.0.0.1:${toString port}";
      behind-proxy = true;
    };
      # iOS can't hold a connection to a self-hosted server: for each message,
      # ntfy.sh gets a poll request (message ID + hashed topic, no content) and
      # wakes the iOS app over APNs, which then fetches the message from here.
      upstream-base-url = "https://ntfy.sh";
  };

  services.caddy.virtualHosts.${url} = mkIf config.components.caddy.enable {
    extraConfig = ''
      import cloudflare
      reverse_proxy http://127.0.0.1:${toString port}
    '';
  };
}
