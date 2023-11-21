{
  self,
  config,
  ...
}: {
  users.mutableUsers = false;
  users.users.admin = {
    uid = 1000;
    description = "admin user";
    isNormalUser = true;
    extraGroups = ["docker" "networkmanager" "wheel"];
    passwordFile = "${config.age.secretsDir}/users/adminPass";
    initialHashedPassword = "$6$ZxJtQlZhhY8ZJjY$R6SqiPBtRh3YRD3Bnyprt0roT6mjvB4F6igRDISsADMJ56J.7YIoRbD9md4MFvQbSEsT1sQGWfxLLcWKV65lV/"; # hack me bro I dare you
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCs1jS9VyF8cR913jEJAhmtz1xPUdGwGLwmun8mbPnaCAS+4OJlxgxhBQTuVch2SjPdGck7LXtmZWF55XO8Na342miEbdKDpMAEf+MR3iA8sxDECwrqvtiwRGgrXtQuR3qXRbrrKn9WTqjKZyng5tcsvcIlQSc7ig23AuF9yifMzyqvSYvaVirS8BKorSDY9aLCqbnH1KTDQWV5H4t4rmF9ixSXAiVhYGu6AXTT4xm7ND+JX7+l91TPHk8e2Sjy/97CjVwivkRtJJzw1szPZqxaDlKm5c+na4fgWlG/zZ1bAXhB4o4S5Js6nbmVtzGiiYvUquGC8BQtLkzMxmyX5jD+17f87vZ5nGH7NbSG52poEha4kZVudmZHN/MoIdJnTRW5NoQO2VqPHDCLLHbZ/6RvNoU81mHMiTTMJpc3mTBUxOcLWREG5RlueA4SQ4B9nqTLlO13iAR8TGGfIRqX1YkhW7GIbhZHacPukDTNuH7A7hjJHapKS36OEUpPgdU+6JNLVAKIG7AJrjfhCv0bowjESyZr89ihub5yZGx5VvrK5COe/sKgqWgNS6hIiSH6ASwBi4QKMeamdrYUm1nyZu9KZrRb+p/vwumnkeCY/m7tmqCLUG4+FHfBvcDjWlGzzidEFSywfsa3O65y4AIdApk+MbeTU6o/s1RsNNTITuJTpQ=="
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1HH8/qgcU63wichBiB5nvSv0+9B9xxWdy2AYQr3oyr"
    ];
  };
  security.sudo.extraRules = [
    {
      users = ["admin"];
      commands = [
        {
          command = "ALL";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
  nix.settings.trusted-users = ["admin"];

  age.secrets = {
    "users/adminPass" = {
      file = "${self}/secrets/users/adminPass.age";
      mode = "440";
      owner = config.users.users.admin;
      group = config.users.users.admin;
    };
  };
}
