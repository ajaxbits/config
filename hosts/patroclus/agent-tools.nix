{ pkgs, ... }:
{
  # Tools omp agents on this host rely on (uvx runs the mcp-nixos MCP server).
  environment.systemPackages = [ pkgs.uv ];

  # uv's downloaded CPython builds are generic-Linux binaries that NixOS can't
  # run; make uv use nixpkgs' interpreter instead.
  environment.variables = {
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON = "${pkgs.python3}/bin/python3";
  };
}
