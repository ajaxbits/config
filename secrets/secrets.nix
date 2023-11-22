# TODO: think about agenix-rekey for this
let
  agamemnon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCc1d8GMX5g84ZFflg8YWJ7rqUlLzVBrc2ENvUqNEGs";
  patroclus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUxl2SlkRLPnP/OgLd5jn0BGasYtNrgZ2YNP1rPIFnA";
  ajax = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1HH8/qgcU63wichBiB5nvSv0+9B9xxWdy2AYQr3oyr";
  aphrodite = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB";

  writers = [ajax aphrodite];

  allKeys = [agamemnon ajax aphrodite patroclus];
in {
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
  "caddy/cloudflareApiToken.age".publicKeys = writers ++ [patroclus];
}
