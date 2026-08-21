{
  config,
  lib,
  unstable,
  pkgsUnstable,
  ...
}:
let
  inherit (lib) mkIf;

  port = 4433;
  url = "https://hister.${config.networking.domain}";
in
{
  # The services.hister module does not exist in the stable nixpkgs (26.05),
  # so pull it in directly from the nixos-unstable input rather than switching
  # the whole system to unstable. The package likewise only exists in unstable,
  # so point the module at pkgsUnstable.hister.
  imports = [ "${unstable}/nixos/modules/services/web-apps/hister.nix" ];

  services.hister = {
    enable = true;
    package = pkgsUnstable.hister;

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

  services.caddy.virtualHosts.${url} = mkIf config.components.caddy.enable {
    extraConfig = ''
      import cloudflare
      reverse_proxy http://127.0.0.1:${toString port}
      encode gzip zstd
    '';
  };
}
