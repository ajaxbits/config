{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.components.paperless;
in {
  options.components.paperless.enable = mkEnableOption "Enable ZFS support";

  config = mkIf cfg.enable {
    services.paperless = {
      enable = true;
      user = "paperless";
      mediaDir = "/data/documents";
      consumptionDirIsPublic = true;

      address = "0.0.0.0";
      passwordFile = "${config.age.secretsDir}/paperless/admin-password";

      extraConfig = {
        PAPERLESS_TIME_ZONE = "America/Chicago";
        # TODO: Get these working
        # PAPERLESS_TIKA_ENABLED = "1";
        # PAPERLESS_TIKA_GOTENBERG_ENDPOINT = "http://paperless-gotenberg:3000";
        # PAPERLESS_TIKA_ENDPOINT = "http://paperless-tika:9998";
      };
    };

    users.users = {
      paperless = {
        isSystemUser = true;
        group = "paperless";
        extraGroups = ["documentsoperators"];
      };
    };
    users.groups = {
      paperless = {};
      documentsoperators = {};
    };

    age.secrets = {
      "paperless/admin-password" = {
        file = "${self}/secrets/paperless/admin-password.age";
        mode = "440";
        owner = config.users.users.paperless.name;
        group = config.users.users.paperless.group;
      };
    };
  };
}
