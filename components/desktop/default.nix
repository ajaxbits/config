{user, ...}: {
  imports = [
    ./wm/sway
    ./browser/firefox
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.backupFileExtension = "bkup";
  home-manager.users.${user} = {...}: {
    programs.home-manager.enable = true;
    home.enableNixpkgsReleaseCheck = true;
  };
}
