[private]
default:
    @just --list

check:
    nix flake check --no-build 2>&1
