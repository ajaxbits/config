{
  inputs,
  system,
  ...
}: {
  caddy = _self: _super: {
    caddy-patched = inputs.caddy.packages.${system}.caddy;
  };
  nur = inputs.nur.overlay;
}
