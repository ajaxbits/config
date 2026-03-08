{
  config,
  lib,
  pkgs,
  dataPaths,
  ...
}:
let
  inherit (lib) mkIf optionalString;

  cfg = config.components.smarthome;

  rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";
  dataset = "zroot/srv/containers";
  sourceSubdir = "smarthome";
  b2Dest = "b2-smarthome-backups:smart-home-backups";
in
{
  config = mkIf cfg.backups.enable {
    systemd.services.smarthome-backup =
      let
        curl = lib.getExe pkgs.curl;
        rclone = lib.getExe pkgs.rclone;
        zfs = lib.getExe' config.boot.zfs.package "zfs";

        backup = pkgs.writeShellScript "smarthome-backup" ''
          set -euo pipefail

          # Find the latest snapshot for the containers dataset
          SNAP=$(${zfs} list -t snapshot -o name -s creation -r ${dataset} | grep "^${dataset}@" | tail -1)
          if [ -z "$SNAP" ]; then
            echo "No snapshots found for ${dataset}" >&2
            exit 1
          fi

          cd "${dataPaths.containers}/.zfs" # The directory is weirdly hidden

          SNAP_NAME="''${SNAP##*@}"
          SNAP_PATH="snapshot/$SNAP_NAME/${sourceSubdir}"

          if [ ! -d "$SNAP_PATH" ]; then
            echo "Snapshot path does not exist: $SNAP_PATH" >&2
            exit 1
          fi

          echo "Backing up from snapshot: $SNAP_NAME"
          echo "Source: $SNAP_PATH"

          ${rclone} sync \
            --config ${rcloneConfigFile} \
            --verbose \
            --checksum \
            --transfers=4 \
            "$SNAP_PATH/" ${b2Dest}

          ${optionalString (
            cfg.backups.healthchecksUrl != ""
          ) "${curl} -fsS -m 10 --retry 5 -o /dev/null ${cfg.backups.healthchecksUrl}"}
        '';
      in
      {
        script = "${backup}";
        serviceConfig = {
          Type = "oneshot";
        };
      };

    systemd.timers.smarthome-backup = {
      description = "Run a smarthome backup on a schedule";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        WakeSystem = true;
        Persistent = true;
      };
    };

    users.groups.rcloneoperators = { };

    # TODO: rethink how agenix secrets are passed in here.
  };
}
