{
  pkgsUnstable,
  config,
  lib,
  ...
}: {
  environment.systemPackages = pkgsUnstable.tailscale;
  services.tailscale = {
    enable = true;
    package = pkgsUnstable.tailscale;
    permitCertUid = lib.mkIf config.services.caddy.enable config.services.caddy.user;
  };
}
