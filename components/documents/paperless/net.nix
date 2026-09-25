# Private host-only link between patroclus and the paperless guest.
{
  bridge = "paperlessbr0";
  # Must not match hosts/patroclus/hypervisor.nix's "vm-*", which joins the LAN bridge.
  tap = "tap-paperless";
  mac = "02:00:00:00:84:02";
  gateway = "192.168.84.1";
  ip = "192.168.84.2";
  cidr = 24;
  port = 28981;
}
