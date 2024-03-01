{
  pkgs,
  lib,
  config,
  overlays,
  user,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.browser.firefox;

  pkgsNUR = pkgs.extend (overlays.nur);
in {
  options.components.desktop.browser.firefox.enable = mkEnableOption "Enable Firefox with extensions.";

  config = mkIf cfg.enable {
    home-manager.users.${user} = {...}: {
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
      };
      xdg.enable = true;

      programs.firefox = {
        enable = true;
        package = pkgsNUR.firefox-wayland;
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
          extensions = with pkgsNUR.nur.repos.rycee.firefox-addons; [
            auto-tab-discard
            bitwarden
            bypass-paywalls-clean
            clearurls
            consent-o-matic
            decentraleyes
            facebook-container
            gruvbox-dark-theme
            i-dont-care-about-cookies
            kagi-search
            multi-account-containers
            privacy-badger
            privacy-possum
            return-youtube-dislikes
            snowflake
            sponsorblock
            temporary-containers
            ublock-origin
            vimium-c
          ];
        };
      };
    };
  };
}
