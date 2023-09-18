{
  config,
  lib,
  inputs,
  ...
}:
with lib; let
  cfg = config.components.miniflux;
in {
  options.components.miniflux.enable = mkEnableOption "Enable Miniflux";

  imports = [inputs.agenix.nixosModules.age];

  config = mkIf cfg.enable {
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
