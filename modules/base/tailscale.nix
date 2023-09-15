{
  pkgs,
  agenix,
  self,
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.modules.tailscale;
in {
  options.modules.tailscale = {
    enable = mkEnableOption "Enable tailscale";
    advertiseRoutes = mkOption {
      description = "A list of subnets to advertise. If empty, the feature is disabled.";
      type = types.listOf types.str;
      default = [];
    };
    acceptRoutes = mkEnableOption "Accept subnet routes from other tailscale nodes";
    tags = mkOption {
      description = "List of additional tags to apply to the node";
      type = types.listOf types.str;
      default = [];
    };
    mullvad = mkEnableOption "Enable mullvad VPN";
  };

  config = mkIf cfg.enable {
    imports = [agenix.nixosModules.age];

    services.tailscale = let
      tags = cfg.tags ++ mkIf cfg.mullvad ["mullvad"];
    in {
      enable = true;
      permitCertUid = mkIf config.services.caddy.enable config.services.caddy.user;
      authKeyFile = "${config.age.secretsDir}/tailscale/authkey";
      extraUpFlags = [
        "--ssh"
        "--advertise-tags=tag:${concatStringsSep ",tag:" tags}"
        # add --advertise-routes flag
      ];
      useRoutingFeatures =
        if acceptRoutes && advertiseRoutes != []
        then "both"
        else if acceptRoutes
        then "client"
        else if advertiseRoutes != []
        then "server"
        else "none";
    };

    # Tailscale wants this setting for: "Strict reverse path filtering breaks Tailscale exit node use and some subnet routing setups"
    # If making tailscale optional in future, consider conditionally setting below if enabled
    networking.firewall.checkReversePath = mkIf (cfg."loose");

    environment.systemPackages = with pkgs; [tailscale];

    age.secrets."tailscale/authkey".file = "${self}/secrets/tailscale/authkey.age";
  };
}
