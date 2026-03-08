{
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.components.smarthome = {
    backups.enable = mkEnableOption "Enable smarthome backup to B2.";
    backups.healthchecksUrl = mkOption {
      description = "Healthchecks.io ping URL for smarthome backup.";
      type = types.str;
      default = "";
    };
  };

  imports = [
    ./backup.nix
  ];
}
