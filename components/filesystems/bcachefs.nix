{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.filesystems.bcachefs;
in {
  options.components.filesystems.bcachefs.enable = mkEnableOption "Enable bcachefs support";

  config = mkIf cfg.enable {
    boot.supportedFilesystems = ["bcachefs"];
    environment.systemPackages = [pkgs.bcachefs-tools];
  };
}
