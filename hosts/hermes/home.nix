{
  user,
  pkgs,
  overlays,
  ...
}: let
  neovimPkgs = pkgs.extend (overlays.neovim);
in {
  manual.html.enable = true;
  programs.man.enable = true;

  xdg.mimeApps.enable = true;
  xdg.mimeApps.defaultApplications = {
    "application/pdf" = ["${pkgs.zathura}/share/applications/org.pwmt.zathura.desktop"];
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
  home.username = user;
  home.homeDirectory = "/home/${user}";

  home.packages = with pkgs; [
    neovimPkgs.neovim

    # CLI tools
    bottom
    feh
    gitAndTools.gh
    mpv
    bunnyfetch
    pazi

    # Wayland!
    wl-clipboard
    xwayland

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
  programs.lazygit = {
    enable = true;
    settings = {
      notARepository = "skip";
      os.openLinkCommand = "${pkgs.firefox}/bin/firefox {{link}} >/dev/null";
    };
  };
}
