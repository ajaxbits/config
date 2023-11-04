{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.components.ebooks;
  ebookDir = "/data/media/books";
in {
  options.components.ebooks.enable = mkEnableOption "Enable ebook server";

  config = mkIf cfg.enable {
    services.calibre-web = {
      enable = true;
      listen.ip = if config.components.caddy.enable then "127.0.0.1" else "0.0.0.0";
      openFirewall = !config.components.caddy.enable;
      options = {
        enableBookUploading = true;
        enableBookConversion = true;
        calibreLibrary = ebookDir;
      };
    };

    users.users = {
      calibreweb = {
        isSystemUser = true;
        group = "calibreweb";
        extraGroups = ["mediaoperators"];
      };
    };
    users.groups = {
      calibreweb = {};
      mediaoperators = {};
    };

    services.caddy.virtualHosts."http://books.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = ''
        encode gzip zstd
        reverse_proxy http://${config.services.calibre-web.listen.ip}:${builtins.toString config.services.calibre-web.listen.port}
      '';
    };
  };
}
