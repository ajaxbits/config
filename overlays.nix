{
  inputs,
  system,
  pkgsUnfree,
  ...
}:
{
  neovim = _self: _super: {
    neovim = inputs.neovim.packages.${system}.default;
  };
  nur = inputs.nur.overlay;
  steam = _self: _super: {
    inherit (pkgsUnfree) steam;
  };
  steam-orig = _self: _super: {
    inherit (pkgsUnfree) steam-orig;
  };
}
