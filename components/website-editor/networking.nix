{ config, lib, pkgs, ... }:
let
  cfg = config.components.website-editor;
  bridge = "agentbr0";
  rules = pkgs.writeText "grace-editor-firewall.nft" (import ./firewall-rules.nix { inherit cfg; });
  cleanup = pkgs.writeText "grace-editor-firewall-stop.nft" ''
    table inet grace_editor;
    delete table inet grace_editor;
  '';
in
{
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.editorPort != cfg.previewPort;
        message = "The website editor and preview must use different ports.";
      }
    ];

    systemd.network = {
      netdevs."30-${bridge}".netdevConfig = {
        Name = bridge;
        Kind = "bridge";
      };
      networks = {
        "30-${bridge}" = {
          matchConfig.Name = bridge;
          address = [ "${cfg.vm.gateway}/${toString cfg.vm.cidr}" ];
          networkConfig = {
            ConfigureWithoutCarrier = true;
            DHCP = "no";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "no";
        };
        "31-agent-grace" = {
          matchConfig.Name = "agent-grace";
          networkConfig = {
            Bridge = bridge;
            DHCP = "no";
            IPv6AcceptRA = false;
            LinkLocalAddressing = "no";
          };
          linkConfig.RequiredForOnline = "no";
        };
      };
    };

    boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

    # Do NOT enable networking.nftables or networking.nat here. On this host's
    # stateVersion, the global nftables service defaults to flushing all tables
    # (including Docker, k3s and Tailscale) and blacklists ip_tables. This service
    # owns exactly one table; nft applies each replacement as one transaction.
    system.build.graceEditorFirewall = rules;
    system.build.graceEditorFirewallCleanup = cleanup;
    system.build.graceEditorNetworkTest = pkgs.writeShellApplication {
      name = "check-grace-editor-network";
      runtimeInputs = with pkgs; [ iproute2 nftables util-linux ];
      text = ''
        # The test creates interfaces, routes and rules only after unshare.
        exec unshare --mount --net --pid --fork --mount-proc \
          ${pkgs.python3}/bin/python3 ${./test-network.py} ${rules} ${cleanup}
      '';
    };
    systemd.services.grace-editor-firewall = {
      description = "Network isolation and LAN port forwarding for Grace's editor";
      before = [ "microvm@grace-editor.service" ];
      reloadIfChanged = true;
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.nftables}/bin/nft --file ${rules}";
        ExecReload = "${pkgs.nftables}/bin/nft --file ${rules}";
        ExecStop = "${pkgs.nftables}/bin/nft --file ${cleanup}";
      };
    };

    # BindsTo plus After means a stopped/failed firewall also stops the guest;
    # on shutdown, the guest stops before its isolation rules are removed.
    systemd.services."microvm@grace-editor" = {
      requires = [ "install-microvm-grace-editor.service" ];
      bindsTo = [ "grace-editor-firewall.service" ];
      after = [ "install-microvm-grace-editor.service" "grace-editor-firewall.service" ];
    };
  };
}
