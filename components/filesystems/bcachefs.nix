{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOverride;
  cfg = config.components.filesystems.bcachefs;
in {
  options.components.filesystems.bcachefs.enable = mkEnableOption "Enable bcachefs support";

  config = mkIf cfg.enable {
    # TODO: fix once bcachefs lands in upstream
    boot.kernelPackages = mkOverride 0 pkgs.linuxPackages_testing_bcachefs.kernel.version;

    boot.supportedFilesystems = ["bcachefs"];
    environment.systemPackages = [pkgs.bcachefs-tools];
  };
}
