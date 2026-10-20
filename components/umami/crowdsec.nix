# Host-side IP reputation for the public collector:
#   CrowdSec LAPI (loopback only) pulls the free Community Blocklist Lite,
#   and the upstream SPOA bouncer answers the guest HAProxy's "is this IP bad?".
# Nothing is shared back to CrowdSec.
{ config, lib, pkgs, ... }:
let
  cfg = config.components.umami;
  net = import ./net.nix;
  lapi = "127.0.0.1:18080"; # :8080 is already taken on patroclus
  keyFile = "/var/lib/umami-crowdsec/api-key";

  bouncer = pkgs.stdenvNoCC.mkDerivation {
    pname = "crowdsec-spoa-bouncer";
    version = "0.4.0";
    src = pkgs.fetchurl {
      url = "https://github.com/crowdsecurity/cs-haproxy-spoa-bouncer/releases/download/v0.4.0/crowdsec-spoa-bouncer-linux-amd64.tgz";
      sha256 = "ffe736576d5eaa21367bb5f2db94dabe80c20917fa024f042273289348ecc143";
    };
    # Upstream static binary; rebuilding needs a newer Go than nixpkgs has.
    installPhase = ''
      install -Dm755 "$(find . -type f -name crowdsec-spoa-bouncer | head -n1)" $out/bin/crowdsec-spoa-bouncer
    '';
    meta.platforms = [ "x86_64-linux" ];
  };

  bouncerConfig = pkgs.writeText "crowdsec-spoa-bouncer.yaml" ''
    log_mode: stdout
    log_level: info
    update_frequency: 10s
    api_url: http://${lapi}/
    api_key: ''${API_KEY}
    listen_tcp: ${net.gateway}:${toString net.spoaPort}
    listen_unix: ""
    prometheus:
      enabled: false
  '';

  start = pkgs.writeShellScript "umami-spoa-start" ''
    API_KEY="$(<"$CREDENTIALS_DIRECTORY/api-key")"
    export API_KEY
    exec ${bouncer}/bin/crowdsec-spoa-bouncer -c ${bouncerConfig}
  '';
in
{
  config = lib.mkIf cfg.enable {
    services.crowdsec = {
      enable = true;
      openFirewall = false;
      autoUpdateService = false;
      # CAPI sends blocklist entries only for scenarios the local agent reports.
      hub.collections = [ "crowdsecurity/base-http-scenarios" ];
      # LAPI won't pull the blocklist until an agent logs in with its scenario
      # list, and the agent refuses to start without a data source. This one
      # has no parser, so it never produces alerts; it only keeps the agent up.
      localConfig.acquisitions = [
        {
          source = "journalctl";
          journalctl_filter = [ "_SYSTEMD_UNIT=umami-spoa.service" ];
          labels.type = "umami-spoa";
        }
      ];
      settings = {
        lapi.credentialsFile = "/var/lib/crowdsec/state/local_api_credentials.yaml";
        capi.credentialsFile = "/var/lib/crowdsec/state/online_api_credentials.yaml";
        general = {
          prometheus.enabled = false;
          api.server = {
            enable = true;
            listen_uri = lapi;
            # Whole attrset on purpose: the module's default is one mkDefault attrset.
            online_client = {
              sharing = false;
              pull = {
                community = true;
                blocklists = false;
              };
              credentials_path = config.services.crowdsec.settings.capi.credentialsFile;
            };
          };
        };
      };
    };

    # cscli refuses to run (even `capi register`) if this file is missing;
    # create it empty so the module's setup can register and fill it in.
    # https://github.com/NixOS/nixpkgs/issues/526506
    systemd.tmpfiles.rules = [
      "f ${config.services.crowdsec.settings.capi.credentialsFile} 0600 ${config.services.crowdsec.user} ${config.services.crowdsec.group} -"
    ];

    # The key is created once by hand (see README); without it this unit just
    # fails and HAProxy answers 503, never unfiltered traffic.
    systemd.services.umami-spoa = {
      description = "CrowdSec SPOA bouncer for the Umami collector";
      wantedBy = [ "multi-user.target" ];
      after = [ "crowdsec.service" "sys-subsystem-net-devices-${net.bridge}.device" "umami-firewall.service" ];
      bindsTo = [ "umami-firewall.service" ];
      unitConfig.ConditionPathExists = keyFile;
      serviceConfig = {
        Type = "notify";
        ExecStart = start;
        LoadCredential = "api-key:${keyFile}";
        Restart = "on-failure";
        RestartSec = 5;
        DynamicUser = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateTmp = true;
        PrivateDevices = true;
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
        IPAddressDeny = "any";
        IPAddressAllow = [ "127.0.0.1" net.ip ];
      };
    };
  };
}
