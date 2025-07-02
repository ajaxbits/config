{
  config,
  self,
  lib,
  ...
}:
let
  cfg = config.components.binary-cache;
  port = 3425;
in
{
  options.components.binary-cache.enable = lib.mkEnableOption "Enable binary cache.";

  config = lib.mkIf cfg.enable {
    services.atticd = {
      enable = true;

      # Replace with absolute path to your environment file
      environmentFile = config.age.secrets."attic/atticd.env".path;

      settings = {
        listen = "127.0.0.1:${builtins.toString port}";

        jwt = { };

        # Data chunking
        #
        # Warning: If you change any of the values here, it will be
        # difficult to reuse existing chunks for newly-uploaded NARs
        # since the cutpoints will be different. As a result, the
        # deduplication ratio will suffer for a while after the change.
        chunking = {
          # The minimum NAR size to trigger chunking
          #
          # If 0, chunking is disabled entirely for newly-uploaded NARs.
          # If 1, all NARs are chunked.
          nar-size-threshold = 64 * 1024; # 64 KiB

          # The preferred minimum size of a chunk, in bytes
          min-size = 16 * 1024; # 16 KiB

          # The preferred average size of a chunk, in bytes
          avg-size = 64 * 1024; # 64 KiB

          # The preferred maximum size of a chunk, in bytes
          max-size = 256 * 1024; # 256 KiB
        };
      };
    };
    services.caddy.virtualHosts."cache.nix.ajax.casa" = lib.mkIf config.components.caddy.enable {
      extraConfig = ''
        import cloudflare
        reverse_proxy :${toString port}
      '';
    };

    age.secrets."attic/atticd.env".file = "${self}/secrets/attic/atticd.env.age";
  };
}
