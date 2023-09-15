{pkgs, ...}: {
  imports = [
    ./git.nix
    ./nix.nix
  ];

  environment.systemPackages = import ./pkgs.nix pkgs;
}
