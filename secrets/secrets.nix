# TODO: think about agenix-rekey for this
let
  agamemnon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCc1d8GMX5g84ZFflg8YWJ7rqUlLzVBrc2ENvUqNEGs";
  bitwarden = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILd+8Pi5rRPT8aLaRAd1YPeBba2zEbTST+9YtzHVugBz";
  hermes = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHVURjOpHel+KZ7NfN3OuXYhu7kGNb7bfq27yJzL6og9";
  patroclus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUxl2SlkRLPnP/OgLd5jn0BGasYtNrgZ2YNP1rPIFnA";
  workMac = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB";

  nixos-rpi-installer = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFfVwO34kka4ZpXxrqHnRAtnEjusFKACRifSkuxW6p5j";

  writers = [
    bitwarden
    workMac
  ];

  allKeys = writers ++ [
    agamemnon
    hermes
    patroclus

    nixos-rpi-installer
  ];
in
{
  # users
  "users/adminPass.age".publicKeys = allKeys;

  # prometheus
  "prometheus/unpoller-pass.age".publicKeys = allKeys;
  "prometheus/nextdns-env.age".publicKeys = allKeys;

  # immich
  "immich/.env.age".publicKeys = allKeys;

  # libation
  "libation/Settings.json.age".publicKeys = allKeys;
  "libation/AccountsSettings.json.age".publicKeys = allKeys;

  # linkding
  "linkding/.env.age".publicKeys = allKeys;

  # forgejo
  "forgejo/postgresql-pass.age".publicKeys = allKeys;

  # miniflux
  "miniflux/adminCredentialsFile.age".publicKeys = allKeys;

  # garnix
  "garnix/github-access-token.age".publicKeys = allKeys;

  # paperless
  "paperless/admin-password.age".publicKeys = allKeys;

  # rclone
  "rclone/rclone.conf.age".publicKeys = allKeys;

  # caddy
  "caddy/cloudflareApiToken.age".publicKeys = writers ++ [ patroclus ];

  # authentik
  "authentik/env.age".publicKeys = writers ++ [ patroclus ];

  # cloudflared
  "cloudflared/creds.json.age".publicKeys = writers ++ [ patroclus ];
  "cloudflared/cert.pem.age".publicKeys = writers ++ [ patroclus ];

  # k3s
  "k3s/common-secret.age".publicKeys = writers ++ [ patroclus ];

  # attic
  "attic/atticd.env.age".publicKeys = writers ++ [ patroclus ];

  # zfs
  "zfs/encryptionPass.age".publicKeys = writers ++ [ nixos-rpi-installer ];
}
