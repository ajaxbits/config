{
  pkgs,
  self,
  config,
  ...
}: let
  healthchecks-url = "https://hc-ping.com/2667f610-dc7f-40db-a753-31101446c823";
  paperless-container-name = config.virtualisation.arion.projects.paperless.settings.services.webserver.service.container_name;
  backup = pkgs.writeShellScript "paperless-backup" ''
    set -eux
    ${pkgs.docker}/bin/docker exec ${paperless-container-name} document_exporter /usr/src/paperless/export --zip
    cd /paperless/export
    mv *.zip paperlessExport.zip
    ${pkgs._7zz}/bin/7zz a -tzip paperlessExportEncrypted.zip -m0=lzma -pBaggage-Crisping-Gloating5 *.zip
    ${pkgs.rclone}/bin/rclone sync paperlessExportEncrypted.zip r2:paperless-backup
    ${pkgs.rclone}/bin/rclone sync paperlessExportEncrypted.zip paperless-s3:alex-jackson-paperless-backups
    rm -rfv /paperless/export/*
    ${pkgs.curl}/bin/curl -fsS -m 10 --retry 5 -o /dev/null ${healthchecks-url}
  '';
in {
  virtualisation.arion.projects.paperless.settings = {
    imports = [./arion-compose.nix];
  };

  systemd.services.paperless-backup-daily = {
    script = "${backup}";
    serviceConfig = {User = "root";};
    startAt = "daily";
  };

  services.syncthing = {
    enable = true;
    dataDir = "/syncthing"; # Default folder for new synced folders
    configDir = "/syncthing/.config/syncthing"; # Folder for Syncthing's settings and keys
    guiAddress = "0.0.0.0:8384";
  };
}
