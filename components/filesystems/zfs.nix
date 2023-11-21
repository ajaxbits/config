{
  config,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkForce mkIf;
  cfg = config.components.filesystems.zfs;
in {
  options.components.filesystems.zfs.enable = mkEnableOption "Enable ZFS support";

  config = mkIf cfg.enable {
    boot.kernelPackages = mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
    boot.supportedFilesystems = ["zfs"];
    boot.zfs.forceImportRoot = false;
  };
}
