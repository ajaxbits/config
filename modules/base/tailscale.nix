{
  pkgs,
  config,
  lib,
  ...
}: {
  environment.systemPackages = with pkgs; [tailscale];
  services.tailscale = {
    enable = true;
    permitCertUid = lib.mkIf config.services.caddy.enable config.services.caddy.user;
  };
}
