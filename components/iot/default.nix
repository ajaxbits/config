{lib, ...}: let
  inherit (lib) mkEnableOption;
in {
  options.components.iot = {
    esphome.enable = mkEnableOption "Enable esphome.";
  };

  imports = [
    ./esphome.nix
  ];
}
