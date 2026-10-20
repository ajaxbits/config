# Private host-only /30 link between patroclus (.1) and the umami guest (.2).
{
  bridge = "umamibr0";
  # Must not match hosts/patroclus/hypervisor.nix's "vm-*", which joins the LAN bridge.
  tap = "tap-umami";
  mac = "02:00:00:00:85:02";
  gateway = "192.168.85.1";
  ip = "192.168.85.2";
  cidr = 30;
  collectorPort = 8080; # guest HAProxy: public tracker, reached only by cloudflared
  port = 3000; # guest Umami: dashboard, reached only by host Caddy
  spoaPort = 9000; # host CrowdSec bouncer: the one thing the guest may call
}
