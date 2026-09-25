{
  config,
  dataPaths,
  inputs,
  lib,
  pkgs,
  self,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.components.documents.paperless;
  net = import ./net.nix;
  publicURL = "https://documents.ajax.casa";
  dataDir = "/var/lib/paperless";
  paperlessDirectoryRules = {
    "${dataDir}".d = {
      mode = "0700";
      user = "paperless";
      group = "paperless";
    };
    "${dataPaths.documents}".d = {
      mode = "0700";
      user = "paperless";
      group = "paperless";
    };
  };
in
{
  imports = [
    inputs.microvm.nixosModules.host
    ./backup.nix
    ./networking.nix
  ];

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = config.components.caddy.enable;
        message = "Paperless MicroVM requires the host Caddy reverse proxy.";
      }
    ];

    # Keep the existing numeric ownership of the shared data and let the host
    # backup job read Paperless exports without exposing backup credentials to
    # the guest.
    users.users.paperless = {
      isSystemUser = true;
      uid = config.ids.uids.paperless;
      group = "paperless";
      extraGroups = lib.optional cfg.backups.enable "rcloneoperators";
    };
    users.groups.paperless.gid = config.ids.gids.paperless;

    systemd.tmpfiles.settings."10-paperless" = paperlessDirectoryRules;

    age.secrets."paperless/admin-password" = {
      file = "${self}/secrets/paperless/admin-password.age";
      path = "/run/paperless-secrets/admin-password";
      mode = "0400";
      owner = "root";
      group = "root";
      symlink = false;
    };
    systemd.tmpfiles.rules = [ "d /run/paperless-secrets 0700 root root - -" ];

    services.caddy.virtualHosts.${publicURL} = {
      extraConfig =
        ''
          encode gzip zstd
          reverse_proxy http://${net.ip}:${toString net.port}
        ''
        + (if config.components.caddy.cloudflare.enable then ''
          import cloudflare
        '' else ''
          tls internal
        '');
    };

    microvm.vms.paperless = {
      inherit pkgs;
      config = {
        system.stateVersion = "26.05";
        networking = {
          hostName = "paperless";
          useDHCP = false;
          enableIPv6 = false;
          firewall.enable = true;
          firewall.allowedTCPPorts = [ net.port ];
        };
        systemd.network = {
          enable = true;
          networks."20-paperless" = {
            matchConfig.Type = "ether";
            address = [ "${net.ip}/${toString net.cidr}" ];
            networkConfig = {
              DHCP = "no";
              IPv6AcceptRA = false;
              LinkLocalAddressing = "no";
            };
          };
        };

        # Keep document ingestion private; unrelated host accounts must not
        # be able to submit files to the document parser.
        services.paperless = {
          enable = true;
          user = "paperless";
          inherit dataDir;
          mediaDir = dataPaths.documents;
          address = "0.0.0.0";
          port = net.port;
          configureTika = true;
          passwordFile = "/run/paperless-secrets/admin-password";
          settings = {
            PAPERLESS_CONSUMER_ASN_BARCODE_PREFIX = "ZB";
            PAPERLESS_CONSUMER_ENABLE_ASN_BARCODE = true;
            PAPERLESS_OCR_USER_ARGS = builtins.toJSON { invalidate_digital_signatures = true; };
            PAPERLESS_TIME_ZONE = "America/Chicago";
            PAPERLESS_URL = publicURL;
            # The guest root and /tmp are tmpfs; exports/OCR need disk-backed scratch.
            PAPERLESS_SCRATCH_DIR = "${dataDir}/scratch";
          };
        };
        systemd.tmpfiles.settings."10-paperless" = paperlessDirectoryRules;

        fileSystems = {
          "${dataDir}".neededForBoot = true;
          "${dataPaths.documents}".neededForBoot = true;
          "/run/paperless-secrets".neededForBoot = true;
        };
        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 4;
          mem = 6144;
          vsock.cid = 10;
          storeOnDisk = true;
          interfaces = [ {
            type = "tap";
            id = net.tap;
            mac = net.mac;
          } ];
          # Keep the established ZFS-backed data paths and snapshots; do not
          # expose the host Nix store or any host-wide secret directory.
          shares = [
            {
              source = dataDir;
              mountPoint = dataDir;
              tag = "paperless-data";
              proto = "virtiofs";
              socket = "paperless-data.socket";
            }
            {
              source = dataPaths.documents;
              mountPoint = dataPaths.documents;
              tag = "paperless-media";
              proto = "virtiofs";
              socket = "paperless-media.socket";
            }
            {
              source = "/run/paperless-secrets";
              mountPoint = "/run/paperless-secrets";
              tag = "paperless-secrets";
              proto = "virtiofs";
              readOnly = true;
              socket = "paperless-secrets.socket";
            }
          ];
        };
      };
    };
  };
}
