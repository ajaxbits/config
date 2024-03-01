{
  lib,
  config,
  user,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.terminal.wezterm;
in {
  options.components.desktop.terminal.wezterm.enable = mkEnableOption "Enable WezTerm terminal.";

  config = mkIf cfg.enable {
    home-manager.users.${user}.programs.wezterm = {
      enable = true;
      extraConfig = builtins.readFile ./config.lua;
    };
  };
}
