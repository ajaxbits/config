{lib, ...}: let
  inherit (lib) mkEnableOption;
in {
  options.components.networking = {
    unifi.enable = mkEnableOption "Enable unifi controller framework.";
  };

  imports = [
    ./unifi
  ];
}
