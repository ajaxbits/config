{
  inputs,
  system,
  ...
}: {
  caddy = _self: _super: {
    caddy-patched = inputs.caddy.packages.${system}.caddy;
  };
  comic-code = _self: _super: {
    comic-code = inputs.comic-code.packages.${system}.default;
  };
  neovim = _self: _super: {
    neovim-full = inputs.neovim.packages.${system}.neovimAJ;
    neovim-min = inputs.neovim.packages.${system}.neovimVSCode;
  };
  nur = inputs.nur.overlay;
}
