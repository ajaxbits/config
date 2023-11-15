{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.components.bcachefs;
in {
  options.components.bcachefs.enable = mkEnableOption "Enable bcachefs support";

  config = mkIf cfg.enable {
    boot.supportedFilesystems = ["bcachefs"];
    environment.systemPackages = [pkgs.bcachefs-tools];
  };
}
