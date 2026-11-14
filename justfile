[private]
default:
    @just --list

check:
    nix flake check --no-build 2>&1

# Tunnel to patroclus's headless Helium session; then VNC to localhost:5900 (TigerVNC, no password)
vnc:
    ssh -L 5900:127.0.0.1:5900 patroclus 'systemctl --user start wayvnc; sleep infinity'
