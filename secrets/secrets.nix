# TODO: think about agenix-rekey for this
let
  agamemnon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCc1d8GMX5g84ZFflg8YWJ7rqUlLzVBrc2ENvUqNEGs";
  # patroclus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILBNlcNWOgrmYIr+imikfZgab1QNzSMWsuR/NgYH1Vwc";
  # patroclus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB37/qiM9qr8fHh5+NaagUFs5lRykN+MutPgzfSqqfc1";
  patroclus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGUxl2SlkRLPnP/OgLd5jn0BGasYtNrgZ2YNP1rPIFnA";
  ajax = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1HH8/qgcU63wichBiB5nvSv0+9B9xxWdy2AYQr3oyr";
  aphrodite = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB";

  allKeys = [agamemnon ajax aphrodite patroclus];
in {
  # prometheus
  "prometheus/unpoller-pass.age".publicKeys = allKeys;
  # libation
  "libation/Settings.json.age".publicKeys = allKeys;
  "libation/AccountsSettings.json.age".publicKeys = allKeys;
  # forgejo
  "forgejo/postgresql-pass.age".publicKeys = allKeys;
  # miniflux
  "miniflux/adminCredentialsFile.age".publicKeys = allKeys;

  # garnix
  "garnix/github-access-token.age".publicKeys = allKeys;
}
