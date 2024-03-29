{
  config,
  lib,
  self,
  ...
}: let
  inherit (lib) boolToString mkEnableOption mkIf;
  cfg = config.components.miniflux;
  url =
    if config.components.caddy.enable
    then "https://feeds.ajax.casa"
    else "http://localhost";
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
        BASE_URL = url;
        WEBAUTHN = boolToString config.components.caddy.enable;
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

    services.caddy.virtualHosts."${url}" = lib.mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${config.services.miniflux.config.LISTEN_ADDR}
        import cloudflare
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
