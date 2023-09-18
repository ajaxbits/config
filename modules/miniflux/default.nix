{
  config,
  lib,
  agenix,
  ...
}:
with lib; let
  cfg = config.modules.miniflux;
in {
  options.modules.miniflux.enable = mkEnableOption "Enable Miniflux";

  config = mkIf cfg.enable {
    imports = [agenix.nixosModules.age];

    services.miniflux = {
      enable = true;
      adminCredentialsFile = "${config.age.secretsDir}/miniflux/adminCredentialsFile";
      config = {
        CLEANUP_FREQUENCY = "48";
        LISTEN_ADDR = "0.0.0.0:4118";
      };
    };

    users.users = {
      miniflux = {
        isSystemUser = true;
        group = "miniflux";
      };
    };
    users.groups = {
      miniflux = {};
    };

    age.secrets = {
      "miniflux/adminCredentialsFile" = {
        file = "${self}/secrets/miniflux/adminCredentialsFile.age";
        mode = "440";
        owner = config.users.users.miniflux.name;
        group = config.users.users.miniflux.group;
      };
    };
  };
}
