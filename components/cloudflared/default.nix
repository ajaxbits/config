{
  config,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.components.cloudflared;
in
{
  options.components.cloudflared = {
    enable = mkEnableOption "Enable cloudflared tunnel for public services.";
    tunnelId = mkOption {
      type = types.str;
      default = "a5466e3c-1170-4a2a-ae62-1a992509f36f";
    };
  };

  config = mkIf cfg.enable {
    services.cloudflared = {
      enable = true;
      package = pkgs.cloudflared;
      tunnels.${cfg.tunnelId} = {
        credentialsFile = config.age.secrets."cloudflared/creds.json".path;
        default = "http_status:404";
      };
    };

    users = {
      users.cloudflared = {
        createHome = true;
        group = "cloudflared";
        home = "/home/cloudflared";
        isSystemUser = true;
      };
      groups.cloudflared = { };
    };

    age.secrets = {
      "cloudflared/creds.json" = {
        file = "${self}/secrets/cloudflared/creds.json.age";
        mode = "440";
        owner = "cloudflared";
        group = "cloudflared";
      };
      "cloudflared/cert.pem" = {
        path = "/home/cloudflared/.cloudflared/cert.pem";
        file = "${self}/secrets/cloudflared/cert.pem.age";
        mode = "440";
        owner = "cloudflared";
        group = "cloudflared";
      };
    };
  };
}
