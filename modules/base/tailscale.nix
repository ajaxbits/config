{
  pkgs,
  config,
  ...
}: {
  environment.systemPackages = with pkgs; [tailscale];
  services.tailscale =
    {
      enable = true;
    }
    // (
      if config.services.caddy.enable == true
      then {
        permitCertUid = config.services.caddy.user;
      }
      else null
    );
}
