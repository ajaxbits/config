{
  config,
  lib,
  overlays,
  user,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.wm.sway;
in {
  options.components.desktop.enable = mkEnableOption "Enable desktop features.";

  imports = [
    ./browser
    ./terminal
    ./wm
    ./bluetooth.nix
  ];

  config = mkIf cfg.enable {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.backupFileExtension = "bkup";
    home-manager.extraSpecialArgs = {inherit overlays user;};
    home-manager.users.${user} = {...}: {
      programs.home-manager.enable = true;
      home.enableNixpkgsReleaseCheck = true;
      home.stateVersion = config.system.nixos.release;
    };
  };
}
