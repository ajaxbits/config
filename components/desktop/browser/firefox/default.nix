{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.browser.firefox;
in {
  options.components.desktop.browser.firefox.enable = mkEnableOption "Enable Firefox with extensions.";

  config = mkIf cfg.enable {
    programs.firefox = let
      workExtensions = [
        "onepassword-password-manager"
        "okta-browser-plugin"
      ];
    in {
      enable = true;
      package = pkgs.firefox-wayland;
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
      };
      # XDG integration
      xdg.enable = true;
      profiles.default = {
        id = 0;
        name = "Default";
        isDefault = true;
        settings = {
          "extensions.update.enabled" = false;
          "xpinstall.signatures.required" = false;
          "browser.uidensity" = 1;
          "browser.aboutConfig.showWarning" = false;
          "browser.shell.checkDefaultBrowser" = false;
        };
      };
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        auto-tab-discard
        bitwarden
        bypass-paywalls-clean
        clearurls
        decentraleyes
        df-youtube
        facebook-container
        kagi-search
        multi-account-containers
        privacy-badger
        privacy-possum
        return-youtube-dislikes
        simple-tab-groups
        snowflake
        sponsorblock
        tab-session-manager
        temporary-containers
        ublock-origin
        vimium
      ];
    };
  };
}
