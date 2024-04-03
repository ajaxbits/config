{lib, ...}: let
  inherit (lib) mkEnableOption;
in {
  options.components.photos.enable = mkEnableOption "Enable photo management";

  imports = [./immich.nix];
}
