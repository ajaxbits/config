{pkgs, ...}: {
  environment.systemPackages = with pkgs; [tailscale];
  services.tailscale = {
    enable = true;
    permitCertUid = "root";
  };
}
