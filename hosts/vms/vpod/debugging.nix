{
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = true;
  };
  users = {
    mutableUsers = true;
    users.admin = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "pleasehackme";
    };
  };
  networking.firewall.allowedTCPPorts = [ 22 ];
}
