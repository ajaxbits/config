{pkgs, ...}: {
  services.netbox = {
    enable = true;
    secretKeyFile = "/var/lib/netbox/secret-key";
    package = pkgs.netbox_4_4;
    listenAddress = "0.0.0.0";
    port = 9452;
  };

  # Generate a secret key on first boot if it doesn't exist
  systemd.tmpfiles.rules = [
    "d /var/lib/netbox 0750 netbox netbox"
  ];

  systemd.services.netbox-secret-key = {
    description = "Generate NetBox secret key";
    wantedBy = [ "multi-user.target" ];
    before = [ "netbox.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "netbox";
      Group = "netbox";
    };
    script = ''
      if [ ! -f /var/lib/netbox/secret-key ]; then
        tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c 50 > /var/lib/netbox/secret-key
        chmod 0400 /var/lib/netbox/secret-key
      fi
    '';
  };
}
