{
  config,
  self,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (builtins) listToAttrs;

  cfg = config.components.syncthing;

  user = "syncthing";
in
{
  options.components.syncthing = {
    enable = mkEnableOption "Enable syncthing server";
  };

  config = mkIf cfg.enable {
    users = {
      users.${user} = {
        group = user;
        isSystemUser = true;
      };
      groups.${user} = { };
    };

    services.syncthing = {
      enable = true;

      inherit user;
      group = user;

      key = config.age.secrets."syncthing/key".path;
      cert = config.age.secrets."syncthing/cert".path;

      openDefaultPorts = true;

      guiAddress = "127.0.0.1:8384";
      guiPasswordFile = config.age.secrets."syncthing/guiPass".path;

      settings = {
        options.urAccepted = -1;
        gui = {
          user = "admin";
          insecureSkipHostcheck = true;
        };
        folders =
          let
            inherit (config.services.syncthing) dataDir;
          in
          {
            insensitive = {
              path = "${dataDir}/insensitive";
              type = "sendreceive";
              # NOTE: this is probably not necessary for insensitive, only for sensitive
              versioning = {
                type = "staggered";
                params = {
                  cleanInterval = "3600";
                  maxAge = "31536000"; # 1 year
                };
              };
            };
          };
      };
    };

    services.caddy.virtualHosts."https://syncthing.ajax.casa" = {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy ${config.services.syncthing.guiAddress}
        import cloudflare
      '';
    };

    age.secrets = listToAttrs (
      map
        (secretName: {
          name = secretName;
          value = {
            file = "${self}/secrets/${secretName}.age";
            mode = "440";
            owner = user;
            group = user;
          };
        })
        [
          "syncthing/guiPass"
          "syncthing/cert"
          "syncthing/key"
        ]
    );
  };
}
