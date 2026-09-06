{ lib, ... }:
let
  inherit (lib) mkEnableOption mkOption types;
in
{
  options.components.website-editor = {
    enable = mkEnableOption "Grace Bobber's isolated website-editor MicroVM";
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
        type = types.str;
        default = "192.168.83.2";
      };
      gateway = mkOption {
        type = types.str;
        default = "192.168.83.1";
      };
      cidr = mkOption {
        type = types.ints.between 0 32;
        default = 24;
      };
    };
  };
}
