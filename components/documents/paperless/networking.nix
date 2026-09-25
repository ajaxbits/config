{ config, lib, pkgs, ... }:
let
  inherit (lib) mkIf;
  cfg = config.components.documents.paperless;
  net = import ./net.nix;
  proxyUid = config.users.users.${config.services.caddy.user}.uid;
  rules = pkgs.writeText "paperless-firewall.nft" (import ./firewall-rules.nix { inherit net proxyUid; });
  cleanup = pkgs.writeText "paperless-firewall-stop.nft" ''
    table inet paperless;
    delete table inet paperless;
  '';
  testSettings = pkgs.writeText "paperless-network-test.json" (builtins.toJSON { inherit net proxyUid; });
in
{
  config = mkIf cfg.enable {
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

    system.build.paperlessFirewall = rules;
    system.build.paperlessFirewallCleanup = cleanup;
    system.build.paperlessNetworkTest = pkgs.writeShellApplication {
      name = "check-paperless-network";
      runtimeInputs = with pkgs; [ iproute2 nftables util-linux ];
      text = ''
        exec unshare --mount --net --pid --fork --mount-proc \
          ${pkgs.python3}/bin/python3 ${./test-network.py} ${rules} ${cleanup} ${testSettings}
      '';
    };

    systemd.services.paperless-firewall = {
      description = "Network isolation for the Paperless MicroVM";
      before = [ "microvm@paperless.service" ];
      reloadIfChanged = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft --file ${rules}";
        ExecReload = "${pkgs.nftables}/bin/nft --file ${rules}";
        ExecStop = "${pkgs.nftables}/bin/nft --file ${cleanup}";
      };
    };
    systemd.services."microvm@paperless" = {
      requires = [ "install-microvm-paperless.service" ];
      bindsTo = [ "paperless-firewall.service" ];
      after = [ "install-microvm-paperless.service" "paperless-firewall.service" ];
    };
  };
}
