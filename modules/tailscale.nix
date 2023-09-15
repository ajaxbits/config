{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
with builtins; let
  cfg = config.modules.tailscale;
in {
  options.modules.tailscale = {
    enable = mkEnableOption "Enable tailscale";
    initialAuthKey = mkOption {
      type = types.str;
      description = "One-time auth key for initial connection. MAKE SURE TO EXPIRE IT IMMEDIATLEY.";
    };

    # routes
    acceptRoutes = mkOption {
      description = "Accept subnet routes from other tailscale nodes";
      type = types.bool;
      default = true;
    };
    advertiseRoutes = mkOption {
      description = "A list of subnets to advertise. If empty, the feature is disabled.";
      type = types.listOf types.str;
      default = [];
    };

    # exit node
    enableExitNode = mkEnableOption "Whether to make node a tailscale exit node.";
    useExitNode = mkOption {
      type = types.str;
      description = "The tailscale exit node to use. If empty, the feature is disabled.";
      default = "";
    };
    useExitNodeLAN = mkEnableOption "Allow direct access to the local network when routing traffic via an exit node";

    # tags
    tags = mkOption {
      description = "List of additional tags to apply to the node";
      type = types.listOf types.str;
      default = [];
    };

    # features
    mullvad = mkEnableOption "Enable mullvad VPN";
    userspaceNetworking = mkEnableOption "Enable userspace networking";
  };

  config = mkIf cfg.enable {
    # service config
    services.tailscale = let
      authKeyFile = toFile "ts-authkey" cfg.initialAuthKey;
      tags = concatStringsSep "," (map (name: "tag:${name}") (cfg.tags ++ mkIf cfg.mullvad ["mullvad"]));
      routes =
        if cfg.advertiseRoutes
        then (concatStringsSep "," cfg.advertiseRoutes)
        else "";
    in {
      inherit authKeyFile;
      enable = true;
      permitCertUid = mkIf config.services.caddy.enable config.services.caddy.user;

      extraUpFlags =
        [
          "--ssh"
          "--exit-node ${cfg.useExitNode}"
          "--advertise-routes '${routes}'"
          "--advertise-tags '${tags}'"
        ]
        ++ (mkIf cfg.acceptRoutes ["--accept-routes"])
        ++ (mkIf cfg.enableExitNode ["--advertise-exit-node"]);

      useRoutingFeatures =
        if acceptRoutes && advertiseRoutes != []
        then "both"
        else if acceptRoutes
        then "client"
        else if advertiseRoutes != []
        then "server"
        else "none";

      interfaceName = mkIf cfg.userspaceNetworking "userspace-networking";
    };

    # CLI
    environment.systemPackages = [pkgs.tailscale];

    # tests
    assertions = [
      {
        assertion = !(cfg.enableExitNode && cfg.useExitNode != "");
        message = "enableExitNode and useExitNode cannot be both defined";
      }
      {
        assertion = authKey != "";
        message = "You must set a tailscale auth key for initial setup";
      }
    ];
  };
}
