{
  config,
  lib,
  overlays,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.wm.sway;
in
{
  options.components.desktop.enable = mkEnableOption "Enable desktop features.";

  imports = [
    ./browser
    ./terminal
    ./wm
    ./bluetooth.nix
  ];

  config = mkIf cfg.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "bkup";
      extraSpecialArgs = { inherit overlays user; };
      users.${user} = {
        programs.home-manager.enable = true;
        home = {
          enableNixpkgsReleaseCheck = true;
          stateVersion = "24.05";
        };
      };
    };
  };
}
