#!/usr/bin/env bash
# A script to perform an initial install. Clone this repo onto the installer image and run it with sudo.

set -euxo pipefail

# The yubikey will be needed for this to work
BW_SESSION=$(bw login --method 3 --raw || bw unlock --raw)
export BW_SESSION
bw get item "Documents ZFS Encryption Passphrase" | jq -r .notes >/tmp/encryption-passphrase

disko --mode destroy,format,mount \
    --arg hostName '"patroclus"' \
    --arg rootPoolName '"zroot"' \
    --arg sectorSizeBytes 512 \
    hosts/patroclus/disks/disks.nix

mkdir -p /mnt/etc/ssh /tmp
bw get item "Patroclus Private Host Keys" | jq -r .sshKey.privateKey >/mnt/etc/ssh/ssh_host_ed25519_key

nom build --accept-flake-config --extra-experimental-features "flakes nix-command" .#nixosConfigurations.patroclusStripped.config.system.build.toplevel

nixos-install --no-root-password --option require-sigs false --flake .#patroclusStripped
