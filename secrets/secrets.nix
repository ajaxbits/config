let
  ajax = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1HH8/qgcU63wichBiB5nvSv0+9B9xxWdy2AYQr3oyr";
  agamemnon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMCc1d8GMX5g84ZFflg8YWJ7rqUlLzVBrc2ENvUqNEGs";
  allKeys = [ajax agamemnon];
in {
  # prometheus
  "prometheus/unpoller-pass.age".publicKeys = [ajax agamemnon];
}
