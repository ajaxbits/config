{lib, ...}: let
  inherit (lib) mkEnableOption;
in {
  import = [./unifi];
}
