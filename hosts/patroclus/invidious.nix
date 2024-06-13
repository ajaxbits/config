let
  domain = "https://yt.ajax.casa";
in {
  services.invidious = {
    inherit domain;
    enable = true;
    address = "127.0.0.1";
    port = 3111;
    settings.db.user = "invidious";
  };

  services.caddy.virtualHosts."${domain}" = {
    extraConfig = ''
      encode gzip zstd
      reverse_proxy http://127.0.0.1:3111
      import cloudflare
    '';
  };
}
