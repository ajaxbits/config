{ pkgs, ... }:
{
  # Tools omp agents on this host rely on (uvx runs the mcp-nixos MCP server).
  environment.systemPackages = [ pkgs.uv ];
}
