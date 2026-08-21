{ unstable, pkgsUnstable, ... }:
{
  # The services.hister module does not exist in the stable nixpkgs (26.05),
  # so pull it in directly from the nixos-unstable input rather than switching
  # the whole system to unstable. The package likewise only exists in unstable,
  # so point the module at pkgsUnstable.hister.
  imports = [ "${unstable}/nixos/modules/services/web-apps/hister.nix" ];

  services.hister = {
    enable = true;
    package = pkgsUnstable.hister;
    port = 4433;

    settings = {
      app = {
        # Hand off to Kagi (not Google) when the local index has no hit. This
        # is a plain browser redirect using the existing Kagi session, not an
        # API call, so no token is required.
        search_url = "https://kagi.com/search?q={query}";
      };
      # Default backend is SQLite (server.database = "db.sqlite3"), stored in
      # the systemd StateDirectory. Postgres is only worth it for multi-user or
      # pgvector-backed semantic search, neither of which applies here.
    };
  };
}
