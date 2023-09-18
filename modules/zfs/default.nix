{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.zfs;
in {
  options.modules.zfs.enable = mkEnableOption "Enable ZFS support";

  config = mkIf cfg.enable {
    boot.kernelPackages = mkForce config.boot.zfs.package.latestCompatibleLinuxPackages;
    boot.supportedFilesystems = ["zfs"];
  };
}
