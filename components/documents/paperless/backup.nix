{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib) mkIf optionalString;
  cfg = config.components.documents.paperless;
  dataDir = "/var/lib/paperless";
  exportDir = "${dataDir}/export";
  uploadMarker = "${exportDir}/.upload-ready";
  stagingDir = "/var/cache/paperless-backup";
in
{
  config = mkIf cfg.backups.enable {

    system.build.paperlessBackupExportTest = pkgs.writeShellApplication {
      name = "check-paperless-backup-export";
      runtimeInputs = [ pkgs.python3 ];
      text = ''
        exec ${pkgs.python3}/bin/python3 ${./.}/test_backup_export.py
      '';
    };
    # The guest writes the encrypted export; only the host uploads it.
    microvm.vms.paperless.config = {
      services.paperless.exporter = {
        enable = true;
        directory = exportDir;
        onCalendar = null;
        settings = {
          compare-checksums = true;
          delete = true;
          no-color = true;
          no-progress-bar = true;
          passphrase = "Baggage-Crisping-Gloating5";
          split-manifest = true;
          zip = true;
          zip-name = "paperlessExportEncrypted";
        };
      };
      systemd.timers.paperless-exporter = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
      systemd.services.paperless-exporter = {
        serviceConfig.Type = "oneshot";
        postStart = ''
          ${pkgs.coreutils}/bin/date --iso-8601=seconds > ${uploadMarker}
        '';
      };
    };

    users.groups.rcloneoperators = { };
    users.users.paperless.extraGroups = [ "rcloneoperators" ];
    age.secrets."rclone/rclone.conf" = {
      file = "${self}/secrets/rclone/rclone.conf.age";
      mode = "440";
      owner = config.users.users.paperless.name;
      group = config.users.groups.rcloneoperators.name;
    };

    systemd.tmpfiles.settings."10-paperless-backup"."${stagingDir}".d = {
      mode = "0700";
      user = "paperless";
      group = "paperless";
    };

    systemd.paths.paperless-backup = {
      description = "Upload a completed Paperless export";
      wantedBy = [ "multi-user.target" ];
      pathConfig = {
        PathChanged = uploadMarker;
        Unit = "paperless-backup.service";
      };
    };

    systemd.services.paperless-backup = {
      description = "Upload encrypted Paperless export to remote storage";
      serviceConfig = {
        Type = "oneshot";
        User = config.users.users.paperless.name;
      };
      script = ''
        set -eu
        # A daily export is legitimate; ignore extra guest-initiated triggers.
        lastUpload=${stagingDir}/.last-upload
        now="$(${pkgs.coreutils}/bin/date +%s)"
        if [ -e "$lastUpload" ] && [ $((now - $(${pkgs.coreutils}/bin/stat -c %Y "$lastUpload"))) -lt 72000 ]; then
          echo "Skipping: last Paperless upload was less than 20h ago."
          exit 0
        fi
        stagedExport="$(${pkgs.python3}/bin/python3 ${./backup_export.py} ${dataDir} ${stagingDir})"
        trap 'rm -f -- "$stagedExport"' EXIT
        stamp="$(${pkgs.coreutils}/bin/date -u +%Y%m%dT%H%M%S.%N)"
        # ponytail: append-only exports grow; apply bucket lifecycle retention if storage cost matters.
        ${pkgs.rclone}/bin/rclone copyto --immutable \
          --config ${config.age.secretsDir}/rclone/rclone.conf \
          --verbose \
          "$stagedExport" "r2:paperless-backup/paperlessExportEncrypted-$stamp.zip"
        ${pkgs.rclone}/bin/rclone copyto --immutable \
          --config ${config.age.secretsDir}/rclone/rclone.conf \
          --verbose \
          "$stagedExport" "b2-paperless-backups:paperless-backups/paperlessExportEncrypted-$stamp.zip"
        ${pkgs.coreutils}/bin/touch "$lastUpload"
        ${optionalString (cfg.backups.healthchecksUrl != "") "${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${cfg.backups.healthchecksUrl}"}
      '';
      unitConfig.ConditionPathExists = uploadMarker;
    };
  };
}
