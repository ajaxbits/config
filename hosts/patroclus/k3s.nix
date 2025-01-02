{
  config,
  self,
  pkgs,
  ...
}:
{
  services.k3s = {
    enable = true;
    clusterInit = true;
    disableAgent = false;
    role = "server";
    tokenFile = config.age.secrets."k3s/common-secret".path;
    extraFlags = [
      "--disable traefik"
    ];
  };

  environment.systemPackages = [
    pkgs.kubectl
    pkgs.nfs-utils
  ];
  services.openiscsi = {
    enable = true;
    name = "${config.networking.hostName}-initiatorhost";
  };

  users = {
    users.k3s = {
      isSystemUser = true;
      group = "k3s";
    };
    groups.k3s = { };
  };
  age.secrets = {
    "k3s/common-secret" = {
      file = "${self}/secrets/k3s/common-secret.age";
      mode = "440";
      owner = "k3s";
      group = "k3s";
    };
  };
}
