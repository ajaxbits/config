{ config, pkgs, lib, ... }:
{
  manual.html.enable = true;
  programs.man.enable = true;


  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [ "${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop" ];
  };

  gtk = {
    enable = true;
    theme = {
      name = "gruvbox-dark";
      package = pkgs.gruvbox-dark-gtk;
    };
    iconTheme = {
      name = "gruvbox-dark-icons";
      package = pkgs.gruvbox-dark-icons-gtk;
    };
    font = {
      name = "Atkinson Hyperlegible";
      package = pkgs.atkinson-hyperlegible;
    };
  };
  home.username = "admin";
  home.homeDirectory = "/home/admin";


  home.packages = with pkgs; [
    # CLI tools
    bottom
    feh
    gitAndTools.gh
    mpv
    bunnyfetch
    pazi

    # # Wayland!
    # # TODO audit if you need these
    # wl-clipboard
    # wofi-emoji-picker
    # launch-rofimoji
    # xwayland
    # wofi

    # GUI Apps
    gnome.nautilus
    remmina

    # system tools
    iw
    libinput-gestures
  ];
  fonts = {
    fontconfig.enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv = {
      enable = true;
    };
  };
  programs.zathura = {
    enable = true;
    extraConfig = "set selection-clipboard clipboard";
  };
  programs.lazygit.settings.os.openLinkCommand = "${pkgs.firefox}/bin/firefox {{link}} >/dev/null";

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "23.11";
}
