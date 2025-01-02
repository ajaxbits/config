{ config, self, ... }:
{
  services.k3s = {
    enable = true;
    clusterInit = true;
    disableAgent = true;
    role = "server";
    tokenFile = config.age.secrets."k3s/common-secret".path;
    extraFlags = [
      "--disable traefik"
    ];
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
