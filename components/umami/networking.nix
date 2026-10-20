{ config, lib, pkgs, ... }:
let
  cfg = config.components.umami;
  net = import ./net.nix;
  uids = {
    cloudflaredUid = config.users.users.cloudflared.uid;
    caddyUid = config.users.users.${config.services.caddy.user}.uid;
  };
  rules = pkgs.writeText "umami-firewall.nft" (import ./firewall-rules.nix ({ inherit net; } // uids));
  cleanup = pkgs.writeText "umami-firewall-stop.nft" ''
    table inet umami;
    delete table inet umami;
  '';
  testSettings = pkgs.writeText "umami-network-test.json" (builtins.toJSON ({ inherit net; } // uids));
  nft = "${pkgs.nftables}/bin/nft";
in
{
  config = lib.mkIf cfg.enable {
    systemd.network = {
      netdevs."30-${net.bridge}".netdevConfig = {
        Name = net.bridge;
        Kind = "bridge";
      };
      networks = {
        "30-${net.bridge}" = {
          matchConfig.Name = net.bridge;
          address = [ "${net.gateway}/${toString net.cidr}" ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
            DHCP = "no";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "no";
        };
        "31-${net.tap}" = {
          matchConfig.Name = net.tap;
          networkConfig = {
            Bridge = net.bridge;
            DHCP = "no";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "no";
        };
      };
    };

    system.build.umamiFirewall = rules;
    system.build.umamiNetworkTest = pkgs.writeShellApplication {
      name = "check-umami-network";
      runtimeInputs = with pkgs; [ iproute2 nftables util-linux ];
      text = ''
        exec unshare --mount --net --pid --fork --mount-proc \
          ${pkgs.python3}/bin/python3 ${./test-network.py} ${rules} ${cleanup} ${testSettings}
      '';
    };

    # Stopping this unit stops the guest and bouncer first (BindsTo), then
    # removes the rules. Operators: `systemctl stop umami-firewall`.
    systemd.services.umami-firewall = {
      description = "Network isolation for the Umami MicroVM";
      before = [ "microvm@umami.service" "umami-spoa.service" ];
      reloadIfChanged = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${nft} --file ${rules}";
        ExecReload = "${nft} --file ${rules}";
        ExecStop = "${nft} --file ${cleanup}";
      };
    };
    systemd.services."microvm@umami" = {
      requires = [ "install-microvm-umami.service" ];
      bindsTo = [ "umami-firewall.service" ];
      after = [ "install-microvm-umami.service" "umami-firewall.service" ];
    };
  };
}
