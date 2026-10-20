# Umami analytics in an offline MicroVM.
#
#   visitor ──Cloudflare──▶ cloudflared ──▶ guest HAProxy :8080 ──▶ Umami :3000
#                                               │ "is this IP bad?"
#                                               ▼
#                                   host CrowdSec bouncer :9000
#   LAN/tailnet ──▶ host Caddy (analytics-grace.ajax.casa) ──▶ Umami :3000
#
# HAProxy only lets through /script.js and /api/send; the dashboard is private.
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.components.umami;
  net = import ./net.nix;
  publicHost = "analytics-grace.ajax.lol";
  privateHost = "analytics-grace.ajax.casa";
  port = toString net.port;

  spoeConfig = pkgs.writeText "crowdsec-spoe.cfg" ''
    [crowdsec]
    spoe-agent crowdsec-agent
        groups crowdsec-ip
        option var-prefix crowdsec
        option set-on-error error
        timeout hello 200ms
        timeout idle 55s
        timeout processing 500ms
        use-backend crowdsec-spoa

    # Sent explicitly per request, after src is set to the real visitor IP.
    spoe-message crowdsec-tcp
        args src-ip=src

    spoe-group crowdsec-ip
        messages crowdsec-tcp
  '';

  allowedHeaders = lib.concatStringsSep "|" [
    "host"
    "user-agent"
    "content-type"
    "content-length"
    "origin"
    "access-control-request-method"
    "access-control-request-headers"
    "x-umami-website-id"
    "x-umami-hostname"
    "x-umami-cache"
  ];

  haproxyConfig = ''
    global
      maxconn 256
      # Fits a full 512 KiB replay chunk plus headers, so body checks see it all.
      tune.bufsize 557056
      log stdout format raw local0 info

    defaults
      mode http
      log global
      log-format "%ci %HM %HPO %ST %Tt crowdsec=%[var(txn.crowdsec.remediation)] spoe_error=%[var(txn.crowdsec.error)]"
      timeout connect 2s
      timeout http-request 10s
      timeout client 10s
      timeout server 15s

    frontend collector
      bind ${net.ip}:${toString net.collectorPort}
      filter spoe engine crowdsec config ${spoeConfig}
      stick-table type ipv6 size 100k expire 1m store http_req_rate(10s)

      # 1. Only cloudflared (via the host) may connect.
      tcp-request connection reject unless { src ${net.gateway} }
      http-request return status 431 if { req.hdrs,length gt 16384 }

      # 2. Exact Host, and exactly one well-formed CF-Connecting-IP → becomes src.
      http-request deny deny_status 400 unless { req.fhdr_cnt(host) eq 1 } { req.fhdr(host) -m str ${publicHost} }
      http-request deny deny_status 400 unless { req.fhdr_cnt(cf-connecting-ip) eq 1 }
      http-request deny deny_status 400 unless { req.fhdr(cf-connecting-ip) -m reg ^[0-9A-Fa-f:.]+$ }
      http-request deny deny_status 400 if { req.fhdr(cf-connecting-ip) -m reg ^[0-9.]+:[0-9]+$ }
      http-request deny deny_status 400 unless { req.hdr_ip(cf-connecting-ip) -m found }
      http-request set-src req.hdr_ip(cf-connecting-ip)

      # 3. Only the tracker and session-replay routes, matched on the raw request target.
      acl script url -m str /script.js /recorder.js
      acl send url -m str /api/send
      acl record url -m str /api/record
      acl recorder_config url -m reg ^/api/websites/[0-9a-f-]{36}/recorder$
      acl get_method method GET HEAD
      acl post_method method POST OPTIONS
      acl config_method method GET HEAD OPTIONS
      http-request deny deny_status 404 unless script get_method or send post_method or record post_method or recorder_config config_method
      acl from_site req.fhdr(origin) -m str https://gracebobber.com https://www.gracebobber.com
      http-request deny deny_status 403 if !script !{ req.fhdr_cnt(origin) eq 1 }
      http-request deny deny_status 403 if !script !from_site

      # 4. Static denylist and per-visitor rate limit.
      ${lib.optionalString (cfg.blockedCidrs != [ ]) ''
        http-request deny deny_status 403 if { src ${lib.concatStringsSep " " cfg.blockedCidrs} }
      ''}
      http-request track-sc0 src
      http-request deny deny_status 429 if { sc_http_req_rate(0) gt 100 }

      # 5. CrowdSec reputation: only an explicit "allow" gets through.
      http-request unset-var(txn.crowdsec.remediation)
      http-request unset-var(txn.crowdsec.error)
      http-request send-spoe-group crowdsec crowdsec-ip
      http-request deny deny_status 403 if { var(txn.crowdsec.remediation) -m str ban captcha challenge }
      http-request deny deny_status 503 unless { var(txn.crowdsec.remediation) -m str allow }

      # 6. Bodies: fixed-length POSTs only (64 KiB, replay chunks 512 KiB), and they must be complete.
      http-request return status 411 if { req.fhdr_cnt(transfer-encoding) gt 0 }
      http-request return status 415 if { req.fhdr_cnt(content-encoding) gt 0 }
      http-request return status 411 if METH_POST !{ req.fhdr_cnt(content-length) eq 1 }
      http-request deny deny_status 413 if METH_POST !record { req.hdr_val(content-length) gt 65536 }
      http-request deny deny_status 413 if METH_POST record { req.hdr_val(content-length) gt 524288 }
      http-request deny deny_status 400 if !METH_POST { req.fhdr_cnt(content-length) gt 0 } !{ req.hdr_val(content-length) eq 0 }
      http-request set-var(txn.expected_length) req.hdr_val(content-length) if METH_POST
      http-request wait-for-body time 10s if METH_POST
      # Valid only because chunked bodies are refused and the length is capped above.
      http-request deny deny_status 400 if METH_POST !{ req.body_len,sub(txn.expected_length) -m int eq 0 }

      # 7. Forward only what Umami needs.
      http-request del-header (?i)^(?!(${allowedHeaders})$) -m reg
      http-request set-header Host ${publicHost}
      http-request set-header X-Real-IP %[src]
      http-request set-header X-Forwarded-For %[src]
      http-request set-header X-Forwarded-Proto https
      http-response del-header set-cookie
      default_backend umami

    backend umami
      server umami 127.0.0.1:${port}

    backend crowdsec-spoa
      mode spop
      server bouncer ${net.gateway}:${toString net.spoaPort}
  '';
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ./crowdsec.nix
    ./networking.nix
  ];

  options.components.umami = {
    enable = lib.mkEnableOption "Umami analytics MicroVM";
    blockedCidrs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Visitor CIDRs the public collector always rejects (403).";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.caddy.enable && config.components.caddy.cloudflare.enable;
        message = "Umami needs host Caddy with Cloudflare DNS for the private dashboard.";
      }
      {
        assertion = config.components.cloudflared.enable;
        message = "Umami's public collector is served through cloudflared.";
      }
    ];

    # Public: tracker only, straight to the guest HAProxy (never via Caddy).
    services.cloudflared.tunnels.${config.components.cloudflared.tunnelId}.ingress.${publicHost} = {
      service = "http://${net.ip}:${toString net.collectorPort}";
      originRequest.httpHostHeader = publicHost;
    };

    # Private: LAN + tailnet only, judged by the real socket peer.
    services.caddy.virtualHosts."https://${privateHost}".extraConfig = ''
      import cloudflare
      route {
        @self remote_ip 127.0.0.0/8 ::1 172.22.0.10 100.122.241.27 fd7a:115c:a1e0::f101:f11d
        respond @self 403
        @outside not remote_ip 172.22.0.0/16 100.64.0.0/10 fd7a:115c:a1e0::/48
        respond @outside 403
        reverse_proxy http://${net.ip}:${port} {
          header_up Host ${privateHost}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto https
          header_up -CF-Connecting-IP
          header_up -True-Client-IP
          header_up -X-Middleware-Subrequest
        }
      }
    '';

    microvm.vms.umami = {
      inherit pkgs;
      autostart = true;
      config = {
        system.stateVersion = "26.05";

        # Offline guest: one static address, no route, DNS, IPv6 or time sync.
        networking = {
          hostName = "umami";
          useDHCP = false;
          enableIPv6 = false;
          nameservers = [ ];
          nftables.enable = true;
          firewall = {
            enable = true;
            allowedTCPPorts = [ ];
            allowPing = false;
            filterForward = true;
            extraInputRules = "ip saddr ${net.gateway} tcp dport { ${toString net.collectorPort}, ${port} } accept";
          };
        };
        services.timesyncd.enable = false;
        systemd.network = {
          enable = true;
          networks."20-umami" = {
            matchConfig.Type = "ether";
            address = [ "${net.ip}/${toString net.cidr}" ];
            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = false;
              LinkLocalAddressing = "no";
            };
          };
        };
        services.journald.extraConfig = "SystemMaxUse=128M";

        services.umami = {
          enable = true;
          settings = {
            HOSTNAME = "0.0.0.0";
            PORT = net.port;
            APP_SECRET_FILE = "/var/lib/umami-secrets/app-secret";
            DISABLE_TELEMETRY = true;
            PRIVATE_MODE = true;
            SKIP_LOCATION_HEADERS = true;
            CLIENT_IP_HEADER = "x-real-ip";
          };
        };
        services.postgresql = {
          package = pkgs.postgresql_17;
          settings.listen_addresses = lib.mkForce ""; # Unix socket only
        };

        # Generate the signing secret once. Never replace an existing (even
        # empty) file: Umami would silently fall back to a guessable secret.
        systemd.services.umami-secret = {
          requiredBy = [ "umami.service" ];
          before = [ "umami.service" ];
          unitConfig.RequiresMountsFor = "/var";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            StateDirectory = "umami-secrets";
            StateDirectoryMode = "0700";
            UMask = "0077";
          };
          script = ''
            f=/var/lib/umami-secrets/app-secret
            if [ ! -e "$f" ]; then
              ${pkgs.openssl}/bin/openssl rand -hex 32 > "$f.tmp" && mv "$f.tmp" "$f"
            fi
            test -s "$f"
          '';
        };

        services.haproxy = {
          enable = true;
          config = haproxyConfig;
        };

        fileSystems."/var".neededForBoot = true;
        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 2;
          mem = 2048;
          vsock.cid = null;
          storeOnDisk = true;
          interfaces = [ {
            type = "tap";
            id = net.tap;
            mac = net.mac;
          } ];
          # Lives in /var/lib/microvms/umami, covered by zroot/system/var snapshots.
          volumes = [ {
            image = "umami-var.img";
            mountPoint = "/var";
            size = 16384;
          } ];
        };
      };
    };
  };
}
