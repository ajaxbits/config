{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.zfs;
in {
  options.components.zfs.enable = mkEnableOption "Enable ZFS support";

  config = mkIf cfg.enable {
    boot.kernelPackages = mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
    boot.supportedFilesystems = ["zfs"];
    boot.zfs.forceImportRoot = false;
  };
}
