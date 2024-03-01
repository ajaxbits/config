{
  pkgs,
  lib,
  config,
  user,
  overlays,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.terminal.wezterm;
  comic-code = (pkgs.extend (overlays.comic-code)).comic-code;
in {
  options.components.desktop.terminal.wezterm.enable = mkEnableOption "Enable WezTerm terminal.";

  config = mkIf cfg.enable {
    fonts.packages = [comic-code];

    home-manager.users.${user}.programs.wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./config.lua;
    };
  };
}
