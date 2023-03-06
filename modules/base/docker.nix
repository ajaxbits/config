{pkgs, ...}: {
  virtualisation.docker = {
    enable = true;
  };

  environment.systemPackages = with pkgs; [docker];
  users.extraUsers.root.extraGroups = ["docker"];
}
