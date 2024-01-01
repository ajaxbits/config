{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
in {
  options.components.photos.enable = mkEnableOption "Enable photo management";

  imports = [./immich.nix];
}
