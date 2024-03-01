{
  inputs,
  system,
  ...
}: {
  caddy = _self: _super: {
    caddy-patched = inputs.caddy.packages.${system}.caddy;
  };
  neovim = _self: _super: {
    neovim-full = inputs.neovim.packages.${system}.neovimAJ;
    neovim-min = inputs.neovim.packages.${system}.neovimVSCode;
  };
  nur = inputs.nur.overlay;

}
