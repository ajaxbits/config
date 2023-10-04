{
  pkgs,
  stdenv,
  ...
}: {
  services.caddy = {
    enable = true;
  };
}
