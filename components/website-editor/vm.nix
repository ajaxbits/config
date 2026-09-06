{ config, lib, inputs, pkgs, ... }:
let
  cfg = config.components.website-editor;
  hostName = "grace-editor";
  repo = "https://github.com/ajaxbits/gracebobber.git";
in
{
  config = lib.mkIf cfg.enable {
    # Intentionally no autostart: run `systemctl start microvm@grace-editor`
    # when the editing environment is wanted.
    microvm.vms.${hostName} = {
      inherit pkgs;
      config = {
        system.stateVersion = "26.05";
        networking = {
          inherit hostName;
          useDHCP = false;
          firewall.enable = true;
          firewall.allowedTCPPorts = [ cfg.editorPort cfg.previewPort ];
        };
        systemd.network = {
          enable = true;
          networks."20-agent" = {
            matchConfig.Type = "ether";
            address = [ "${cfg.vm.ip}/${toString cfg.vm.cidr}" ];
            routes = [ { Gateway = cfg.vm.gateway; } ];
            networkConfig.DNS = [ "1.1.1.1" "1.0.0.1" ];
          };
        };

        users.users.agent = {
          isNormalUser = true;
          uid = 1000;
          group = "users";
          home = "/home/agent";
          createHome = true;
          extraGroups = [ "wheel" ];
        };
        security.sudo.wheelNeedsPassword = false;

        environment.systemPackages = with pkgs; [
          inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2
          bash
          curl
          exiftool
          fd
          git
          imagemagick
          jj
          just
          nodejs_22
          poppler-utils
          pkg-config
          ripgrep
          vips
        ];

        microvm = {
          hypervisor = "cloud-hypervisor";
          vcpu = 4;
          mem = 6144;
          vsock.cid = 9;
          storeOnDisk = true;
          interfaces = [ {
            type = "tap";
            id = "agent-grace";
            mac = "02:00:00:00:83:02";
          } ];
          volumes = [
            {
              image = "grace-editor-data.img";
              # This is the only durable workspace visible to the agent.
              # Keeping the home directory on the volume preserves the jj
              # checkout, OpenCode sessions, credentials, and uploaded files.
              mountPoint = "/home/agent";
              size = 32768;
            }
            {
              image = "grace-editor-nix-overlay.img";
              mountPoint = "/nix/.rw-store";
              size = 12288;
            }
          ];
          writableStoreOverlay = "/nix/.rw-store";
        };

        systemd.services.grace-editor-bootstrap = {
          description = "Initialize Grace Bobber website checkout";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          path = with pkgs; [ git jj nodejs_22 ];
          serviceConfig = {
            Type = "oneshot";
            User = "agent";
            WorkingDirectory = "/home/agent";
          };
          script = ''
            if [ ! -d gracebobber/.git ]; then
              git clone ${repo} gracebobber
            fi
            cd gracebobber
            if [ ! -d .jj ]; then
              jj git init --colocate
            fi
            if [ ! -d node_modules ]; then
              npm ci
            fi
          '';
        };
        systemd.services.opencode2-grace-editor = {
          description = "OpenCode web editor for Grace Bobber's website";
          wantedBy = [ "multi-user.target" ];
          after = [ "grace-editor-bootstrap.service" ];
          requires = [ "grace-editor-bootstrap.service" ];
          serviceConfig = {
            User = "agent";
            WorkingDirectory = "/home/agent/gracebobber";
            Environment = [
              "HOME=/home/agent"
              "GRACE_EDITOR_PREVIEW_URL=http://172.22.0.10:${toString cfg.previewPort}"
            ];
            ExecStart = "${inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2}/bin/opencode2 serve --hostname 0.0.0.0 --port ${toString cfg.editorPort}";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
        systemd.services.grace-editor-preview = {
          description = "Astro preview for Grace Bobber's website";
          wantedBy = [ "multi-user.target" ];
          after = [ "grace-editor-bootstrap.service" ];
          requires = [ "grace-editor-bootstrap.service" ];
          serviceConfig = {
            User = "agent";
            WorkingDirectory = "/home/agent/gracebobber";
            ExecStart = "${pkgs.nodejs_22}/bin/npm run dev -- --host 0.0.0.0 --port ${toString cfg.previewPort} --strictPort";
            Restart = "on-failure";
            RestartSec = 5;
          };
        };
      };
    };
  };
}
