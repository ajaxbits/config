{
  config,
  self,
  pkgs,
  ...
}:
{

  environment.systemPackages =
    let
      inherit (pkgs) util-linux kubectl nfs-utils;
    in
    [
      kubectl
      nfs-utils
      # longhorn requires nsenter, this package provides it
      util-linux
    ];

  # Link nix installed binaries to a path expected by longhorn.
  # https://github.com/longhorn/longhorn/issues/2166
  # system.activationScripts.linkBinaries.text = ''
  #   mkdir -p /usr/local
  #   if [[ ! -h "/usr/local/bin" ]]; then
  #     ln -s /run/current-system/sw/bin /usr/local
  #   fi
  # '';

  # longhorn looks for nsenter in specific paths, /usr/local/bin is one of
  # them so symlink the entire system/bin directory there.
  # https://github.com/longhorn/longhorn/issues/2166#issuecomment-1864656450
  systemd.tmpfiles.rules = [ "L+ /usr/local/bin - - - - /run/current-system/sw/bin/" ];

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
  services = {
    k3s = {
      enable = true;
      clusterInit = true;
      disableAgent = false;
      role = "server";
      tokenFile = config.age.secrets."k3s/common-secret".path;
      extraFlags = [
        "--disable traefik"
      ];
    };

    openiscsi = {
      enable = true;
      name = "${config.networking.hostName}-initiatorhost";
    };

    caddy.virtualHosts."https://api.k.ajax.casa" = {
      extraConfig = ''
        reverse_proxy https://127.0.0.1:6443
        import cloudflare
      '';
    };
  };
}
