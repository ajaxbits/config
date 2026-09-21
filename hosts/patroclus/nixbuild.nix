{
  programs.ssh = {
    extraConfig = ''
      Host eu.nixbuild.net
        PubkeyAcceptedKeyTypes ssh-ed25519
        ServerAliveInterval 60
        IdentityFile /etc/ssh/ssh_host_ed25519_key
    '';

    knownHosts.nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };

  nix = {
    distributedBuilds = true;
    settings.builders-use-substitutes = true;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "aarch64-linux";
        maxJobs = 100;
        supportedFeatures = [
          "benchmark"
          "big-parallel"
          "ca-derivations"
          "kvm"
          "nixos-test"
        ];
      }
    ];
  };
}
