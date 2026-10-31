{
  config,
  dataPaths,
  lib,
  pkgs,
  pkgsUnstable,
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

  cfg = config.components.music;
in
{
  options.components.music = {
    enable = mkEnableOption "Enable music component (Navidrome + beets).";
    port = mkOption {
      type = types.port;
      description = "Port to listen on.";
      default = 4533;
    };
    address = mkOption {
      type = types.str;
      description = "Address to listen on.";
      default = "127.0.0.1";
    };
    musicDir = mkOption {
      type = types.str;
      description = "Directory where music is";
      default = "${dataPaths.media}/music";
    };
  };

  config = mkIf cfg.enable {
    age.secrets."navidrome/env" = {
      file = "${self}/secrets/navidrome/env.age";
      owner = config.services.navidrome.user;
    };

    services.navidrome = {
      environmentFile = config.age.secrets."navidrome/env".path;
      enable = true;
      package = pkgsUnstable.navidrome; # 0.64.2 fixes slow-storage scans and a download header injection
      settings = {
        Address = cfg.address;
        Port = cfg.port;
        MusicFolder = cfg.musicDir;
        EnableInsightsCollector = false;
      };
    };

    users.users.navidrome.extraGroups = [ "mediaoperators" ];

    environment.systemPackages = [ pkgs.beets ];

    services.caddy.virtualHosts = mkIf config.components.caddy.enable {
      "https://music.ajax.casa".extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${cfg.address}:${toString cfg.port}
        import cloudflare
      '';
    };
  };
}
