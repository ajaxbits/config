{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  imports = [
    ./forgejo
  ];

  options.components.development = {
    forge = {
      enable = mkEnableOption "Enable self-hosted git forge.";
    };
  };
}
