{
  config,
  lib,
  self,
  ...
}:
let
  inherit (lib) mkIf;

  port = 4433;
  url = "https://hister.${config.networking.domain}";
in
{
  services.hister = {
    enable = true;
    # Hister maps this environment variable to app.access_token, keeping MCP
    # authentication out of the world-readable Nix store.
    environmentFile = config.age.secrets."hister/env".path;

    settings = {
      app = {
        # Hand off to Kagi (not Google) when the local index has no hit. This
        # is a plain browser redirect using the existing Kagi session, not an
        # API call, so no token is required.
        search_url = "https://kagi.com/search?q={query}";
      };
      server = {
        # Listen on all interfaces so Caddy (and the network) can reach it.
        address = "0.0.0.0:${toString port}";
        # Required when address uses 0.0.0.0; must match the public URL.
        base_url = url;
      };
      # Default backend is SQLite (server.database = "db.sqlite3"), stored in
      # the systemd StateDirectory. Postgres is only worth it for multi-user or
      # pgvector-backed semantic search, neither of which applies here.
    };
  };

  age.secrets."hister/env".file = "${self}/secrets/hister/env.age";

  services.caddy.virtualHosts.${url} = mkIf config.components.caddy.enable {
    extraConfig = ''
      import cloudflare
      reverse_proxy http://127.0.0.1:${toString port}
      encode gzip zstd
    '';
  };
}
