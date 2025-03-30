{
  self,
  config,
  pkgs,
  user,
  ...
}:
{
  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.fish;
    users.${user} = {
      uid = 1000;
      description = "admin user";
      isNormalUser = true;
      extraGroups = [
        "docker"
        "networkmanager"
        "wheel"
      ];
      hashedPasswordFile = config.age.secrets."users/adminPass".path;
      openssh.authorizedKeys.keys = [
        "ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBPocbRyxNvg6osesgjnD0cqCR8pqwhbNbmD793Y6uSQHNX3WDBcfQn3BVdDx36WgFeP/3uLzKIomIjuiJyn+ugQ="
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID7omQh72mDWAsnJlXmcNaQOhGKfSj1xpjUVGjAQ5AdB"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILd+8Pi5rRPT8aLaRAd1YPeBba2zEbTST+9YtzHVugBz"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM1HH8/qgcU63wichBiB5nvSv0+9B9xxWdy2AYQr3oyr"
        "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCs1jS9VyF8cR913jEJAhmtz1xPUdGwGLwmun8mbPnaCAS+4OJlxgxhBQTuVch2SjPdGck7LXtmZWF55XO8Na342miEbdKDpMAEf+MR3iA8sxDECwrqvtiwRGgrXtQuR3qXRbrrKn9WTqjKZyng5tcsvcIlQSc7ig23AuF9yifMzyqvSYvaVirS8BKorSDY9aLCqbnH1KTDQWV5H4t4rmF9ixSXAiVhYGu6AXTT4xm7ND+JX7+l91TPHk8e2Sjy/97CjVwivkRtJJzw1szPZqxaDlKm5c+na4fgWlG/zZ1bAXhB4o4S5Js6nbmVtzGiiYvUquGC8BQtLkzMxmyX5jD+17f87vZ5nGH7NbSG52poEha4kZVudmZHN/MoIdJnTRW5NoQO2VqPHDCLLHbZ/6RvNoU81mHMiTTMJpc3mTBUxOcLWREG5RlueA4SQ4B9nqTLlO13iAR8TGGfIRqX1YkhW7GIbhZHacPukDTNuH7A7hjJHapKS36OEUpPgdU+6JNLVAKIG7AJrjfhCv0bowjESyZr89ihub5yZGx5VvrK5COe/sKgqWgNS6hIiSH6ASwBi4QKMeamdrYUm1nyZu9KZrRb+p/vwumnkeCY/m7tmqCLUG4+FHfBvcDjWlGzzidEFSywfsa3O65y4AIdApk+MbeTU6o/s1RsNNTITuJTpQ=="
      ];
    };
  };
  security.sudo.extraRules = [
    {
      users = [ user ];
      commands = [
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
  nix.settings.trusted-users = [ user ];

  age.secrets = {
    "users/adminPass" = {
      file = "${self}/secrets/users/adminPass.age";
      mode = "440";
      owner = config.users.users.root.name;
      group = config.users.users.root.group;
    };
  };
}
