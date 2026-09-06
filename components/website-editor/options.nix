{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.components.website-editor = {
    enable = mkEnableOption "Grace Bobber's isolated website-editor MicroVM";
    lan = {
      interface = mkOption {
        type = types.strMatching "[a-zA-Z0-9_.-]+";
        default = "br0";
        description = "Existing LAN interface; never attached to the guest bridge.";
      };
      hostIP = mkOption {
        type = types.strMatching "[0-9.]+";
        default = "172.22.0.10";
        description = "Only connections addressed to this host IPv4 address are forwarded.";
      };
      cidr = mkOption {
        type = types.strMatching "[0-9.]+/[0-9]+";
        default = "172.22.0.0/15";
        description = "LAN client IPv4 subnet allowed to use the editor and preview.";
      };
    };
    editorPort = mkOption {
      type = types.port;
      default = 4096;
      description = "Host port forwarded to the OpenCode web UI.";
    };
    previewPort = mkOption {
      type = types.port;
      default = 4321;
      description = "Host port forwarded to the Astro preview server.";
    };
    vm = {
      ip = mkOption {
        type = types.strMatching "[0-9.]+";
        default = "192.168.83.2";
      };
      gateway = mkOption {
        type = types.strMatching "[0-9.]+";
        default = "192.168.83.1";
      };
      cidr = mkOption {
        type = types.ints.between 0 32;
        default = 24;
      };
    };
  };
}
