{ config, lib, inputs, pkgs, ... }:
let
  cfg = config.components.website-editor;
  hostConfig = config;
  hostName = "grace-editor";
  repo = "git@github.com:ajaxbits/gracebobber.git";
  tools = with pkgs; [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.opencode2
    bash
    curl
    exiftool
    fd
    git
    gh
    imagemagick
    jujutsu
    jq
    just
    nodejs_22
    openssh
    poppler-utils
    pkg-config
    python3
    ripgrep
    vips
  ];
  globalOpenCodeConfig = pkgs.writeText "grace-editor-opencode.json" (builtins.toJSON {
    "$schema" = "https://opencode.ai/config.json";
    update = "disable";
    warming = false;
  });
in
{
  config = lib.mkIf cfg.enable {
    programs.ssh.extraConfig = ''
      Host grace-editor
        HostName ${cfg.vm.ip}
        User agent
        IdentityFile ~/.ssh/grace-editor
        IdentitiesOnly yes
    '';

    age.secrets."grace-editor/opencode.env" = {
      file = ../../secrets/grace-editor/opencode.env.age;
      path = "/run/grace-editor-secrets/opencode.env";
      mode = "0400";
      # The guest mounts this directory. A real file is required because the
      # agenix default symlink points into /run/agenix, which is not shared.
      symlink = false;
    };
    # Intentionally no autostart: run `systemctl start microvm@grace-editor`
    # when the editing environment is wanted.
    microvm.vms.${hostName} = {
      inherit pkgs;
      autostart = false;
      config = {
        system.stateVersion = "26.05";
        networking = {
          inherit hostName;
          useDHCP = false;
          enableIPv6 = false;
          firewall.enable = true;
          firewall.allowedTCPPorts = [ cfg.editorPort cfg.previewPort ];
        };
        systemd.network = {
          enable = true;
          networks."20-agent" = {
            matchConfig.Type = "ether";
            address = [ "${cfg.vm.ip}/${toString cfg.vm.cidr}" ];
            routes = [ { Gateway = cfg.vm.gateway; } ];
            networkConfig = {
              DNS = [ "1.1.1.1" "1.0.0.1" ];
              DHCP = "no";
              IPv6AcceptRA = false;
              LinkLocalAddressing = "no";
            };
          };
        };

        users.users.agent = {
          isNormalUser = true;
          uid = 1000;
          group = "users";
          home = "/home/agent";
          createHome = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = cfg.authorizedKeys;
        };
        security.sudo.wheelNeedsPassword = false;

        environment.systemPackages = tools;
        nix.settings.experimental-features = [ "nix-command" "flakes" ];
        # GitHub's published Ed25519 host key (https://api.github.com/meta).
        # First-boot cloning must not block on an interactive trust prompt.
        programs.ssh.knownHosts."github.com".publicKey =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

        services.openssh = {
          enable = true;
          openFirewall = false;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = "no";
            AllowUsers = [ "agent" ];
          };
          hostKeys = [ {
            path = "/home/agent/.ssh-host-keys/ssh_host_ed25519_key";
            type = "ed25519";
          } ];
        };
        # Management is host-initiated; the host forwards only the web ports.
        networking.firewall.extraCommands = ''
          iptables -A nixos-fw -s ${cfg.vm.gateway}/32 -p tcp --dport 22 -j nixos-fw-accept
        '';
        networking.firewall.extraStopCommands = ''
          iptables -D nixos-fw -s ${cfg.vm.gateway}/32 -p tcp --dport 22 -j nixos-fw-accept 2>/dev/null || true
        '';

        # A newly formatted volume has a root-owned filesystem root. User
        # creation alone doesn't chown an existing home/mount point.
        fileSystems."/home/agent".neededForBoot = true;
        systemd.tmpfiles.rules = [
          "d /home/agent 0700 agent users -"
          "d /home/agent/.ssh-host-keys 0700 root root -"
          "d /home/agent/.config 0700 agent users -"
          "d /home/agent/.config/opencode 0700 agent users -"
          # Update policy is global-only in V2. L (without +) preserves an
          # existing guest configuration rather than overwriting user edits.
          "L /home/agent/.config/opencode/opencode.json - - - - ${globalOpenCodeConfig}"
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
          # This is the only host secret made visible to the guest. It is a
          # read-only directory, rather than the host-wide agenix directory.
          shares = [ {
            source = "/run/grace-editor-secrets";
            mountPoint = "/run/grace-editor-secrets";
            tag = "opencode-env";
            proto = "virtiofs";
            readOnly = true;
          } ];
        };

        systemd.services.grace-editor-bootstrap = {
          description = "Initialize Grace Bobber website checkout";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];
          path = tools;
          environment.HOME = "/home/agent";
          unitConfig.RequiresMountsFor = "/home/agent";
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "agent";
            WorkingDirectory = "/home/agent";
            TimeoutStartSec = "15min";
          };
          script = ''
            export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o ConnectTimeout=15"
            if [ ! -d gracebobber/.git ]; then
              git clone ${repo} gracebobber
            fi
            cd gracebobber
            if [ -z "$(jj config get user.name 2>/dev/null || true)" ]; then
              jj config set --user user.name "Grace website editor"
            fi
            if [ -z "$(jj config get user.email 2>/dev/null || true)" ]; then
              jj config set --user user.email "grace-editor@localhost"
            fi
            if [ ! -d .jj ]; then
              jj git init --colocate
              jj bookmark track main --remote=origin
            fi
            # A failed npm ci may leave node_modules behind. Only record the
            # lockfile and Node version once an installation actually succeeds.
            signature="$(sha256sum package-lock.json | cut -d ' ' -f1):$(node --version)"
            if [ ! -x node_modules/.bin/astro ] ||
               [ "$(cat node_modules/.grace-editor-deps 2>/dev/null || true)" != "$signature" ]; then
              npm ci
              printf '%s\n' "$signature" > node_modules/.grace-editor-deps
            fi
          '';
        };
        systemd.services.opencode2-grace-editor = {
          description = "OpenCode web editor for Grace Bobber's website";
          wantedBy = [ "multi-user.target" ];
          after = [ "grace-editor-bootstrap.service" ];
          requires = [ "grace-editor-bootstrap.service" ];
          path = tools ++ [ "/run/wrappers" "/run/current-system/sw" ];
          serviceConfig = {
            User = "agent";
            WorkingDirectory = "/home/agent/gracebobber";
            Environment = [
              "HOME=/home/agent"
              "GRACE_EDITOR_PREVIEW_URL=http://${cfg.lan.hostIP}:${toString cfg.previewPort}"
              "GRACE_EDITOR_PREVIEW_CHECK_URL=http://127.0.0.1:${toString cfg.previewPort}"
            ];
            EnvironmentFile = hostConfig.age.secrets."grace-editor/opencode.env".path;
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
          path = tools;
          environment.HOME = "/home/agent";
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
