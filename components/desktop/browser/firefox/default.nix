{
  pkgs,
  lib,
  config,
  user,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.components.desktop.browser.firefox;
in
{
  options.components.desktop.browser.firefox.enable =
    mkEnableOption "Enable Firefox with extensions.";

  config = mkIf cfg.enable {
    home-manager.users.${user} = _: {
      home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
      };
      xdg.enable = true;

      programs.firefox = {
        enable = true;
        package = pkgs.firefox-wayland;
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
            "browser.fullscreen.autohide" = false;
          };
          extensions = with pkgs.nur.repos.rycee.firefox-addons; [
            auto-tab-discard
            bitwarden
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
            sidebery
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
