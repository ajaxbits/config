{
  config,
  lib,
  self,
  ...
}:
with lib; let
  cfg = config.components.miniflux;
in {
  options.components.miniflux.enable = mkEnableOption "Enable Miniflux";

  config = mkIf cfg.enable {
    services.miniflux = {
      enable = true;
      adminCredentialsFile = "${config.age.secretsDir}/miniflux/adminCredentialsFile";
      config = {
        CLEANUP_FREQUENCY = "48";
        LISTEN_ADDR =
          if config.components.caddy.enable
          then "127.0.0.1:4118"
          else "0.0.0.0:4118";
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

    services.caddy.virtualHosts."http://feeds.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${config.services.miniflux.config.LISTEN_ADDR}
      '';
    };

    age.secrets = {
      "miniflux/adminCredentialsFile" = {
        file = "${self}/secrets/miniflux/adminCredentialsFile.age";
        mode = "440";
        owner = config.users.users.miniflux.name;
        inherit (config.users.users.miniflux) group;
      };
    };
  };
}
