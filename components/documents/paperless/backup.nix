{
  config,
  lib,
  self,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf optionalString;

  cfg = config.components.documents.paperless;

  backupEncryptionPassword = "Baggage-Crisping-Gloating5"; # not a secret, only for cloud privacy
in
{
  config = mkIf cfg.backups.enable {
    services.paperless.exporter = {
      enable = true;
      onCalendar = null;
      settings = {
        compare-checksums = true; # Compare file checksums when determining whether to export a file or not. If not specified, file size and time modified is used instead.
        delete = true; # After exporting, delete files in the export directory that do not belong to the current export, such as files from deleted documents.
        no-color = true;
        no-progress-bar = true;
        passphrase = backupEncryptionPassword;
        split-manifest = true; # Export document information in individual manifest json files.
        zip = true;
        zip-name = "paperlessExportEncrypted"; # .zip is automatically appended by the system
      };
    };

    systemd.timers.paperless-exporter = {
      description = "Run a paperless export on a schedule";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        WakeSystem = true;
        Persistent = true;
      };
    };

    systemd.services.paperless-backup =
      let
        inherit (cfg.backups) healthchecksUrl;

        rcloneConfigFile = "${config.age.secretsDir}/rclone/rclone.conf";
        exporterService = [ "paperless-exporter.service" ];

        exportDir = config.services.paperless.exporter.directory;
        exportName = "${config.services.paperless.exporter.settings.zip-name}.zip";
        exportPath = "${exportDir}/${exportName}";

        backup =
          let
            curl = lib.getExe pkgs.curl;
            rclone = lib.getExe pkgs.rclone;
          in
          pkgs.writeShellScript "paperless-backup" ''
            set -eux

            ${rclone} sync \
              --config ${rcloneConfigFile} \
              --verbose \
              ${exportPath} r2:paperless-backup
            ${rclone} sync \
              --config ${rcloneConfigFile} \
              --verbose \
              ${exportPath} b2-paperless-backups:paperless-backups

            ${optionalString (
              healthchecksUrl != ""
            ) "${curl} -fsS -m 10 --retry 5 -o /dev/null ${healthchecksUrl}"}
          '';
      in
      {
        script = "${backup}";
        serviceConfig.User = config.services.paperless.user;
        after = exporterService;
        requires = exporterService;
      };

    users.users.paperless.extraGroups = [ "rcloneoperators" ];
    users.groups.rcloneoperators = { };

    age.secrets = {
      "rclone/rclone.conf" = {
        file = "${self}/secrets/rclone/rclone.conf.age";
        mode = "440";
        owner = config.users.users.paperless.name;
        group = config.users.groups.rcloneoperators.name;
      };
    };
  };
}
