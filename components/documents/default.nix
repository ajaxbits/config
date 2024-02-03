{lib, ...}: let
  inherit (lib) mkEnableOption mkOption types;
in {
  imports = [
    ./paperless
    ./stirlingPdf
  ];

  options.components.documents = {
    paperless = {
      enable = mkEnableOption "Enable Paperless component";
      backups = {
        enable = mkEnableOption "Enable backups for paperless documents";
        healthchecksUrl = mkOption {
          description = "Healthchecks endpoint for backup monitoring";
          type = types.str;
        };
      };
    };
    stirlingPdf = {
      enable = mkEnableOption "Enable stirlingPdf pdf editing suite.";
    };
  };
}
