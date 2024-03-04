{
  pkgs,
  lib,
  config,
  user,
  ...
}: let
  inherit (lib) mkEnableOption mkIf mkOptionDefault;
  fs = lib.fileset;

  cfg = config.components.desktop.wm.sway;

  colors = import ../../colors.nix;
  wallpaper =
    pkgs.stdenv.mkDerivation
    {
      name = "wallpaper";
      src = fs.toSource {
        root = ../../.;
        fileset = fs.maybeMissing ../../wallpaper.jpg;
      };
      dontUnpack = true;
      dontConfigure = true;
      installPhase = "cp $src/* $out";
    };

  left = "h";
  down = "j";
  up = "k";
  right = "l";
  modifier = "Mod1";

  terminal = "${pkgs.wezterm}/bin/wezterm";
  web = "${pkgs.firefox}/bin/firefox";
in {
  options.components.desktop.wm.sway.enable = mkEnableOption "Enable Sway WM";

  config = mkIf cfg.enable {
    programs.sway.enable = true;
    security.pam.services.swaylock = {
      text = ''
        auth include login
      '';
    };
    xdg = {
      portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
          xdg-desktop-portal-kde
        ];
      };
    };

    # A/V
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    environment.systemPackages = with pkgs; [
      pavucontrol
      helvum
    ];

    # Enable fonts
    fonts = {
      packages = with pkgs; [
        atkinson-hyperlegible
        font-awesome
        (nerdfonts.override {fonts = ["Iosevka"];})
      ];
      fontconfig = {
        enable = true;
        allowBitmaps = true;
        useEmbeddedBitmaps = true;
      };
      fontDir.enable = true;
    };

    home-manager.users.${user} = {config, ...}: {
      programs.i3status-rust = {
        enable = true;
        bars.bottom = {
          blocks = [
            {
              block = "net";
              format = " $icon  $ip ";
              format_alt = " $icon ^icon_net_down $speed_down.eng(prefix:K) ^icon_net_up $speed_up.eng(prefix:K) ";
            }
            {
              block = "disk_space";
              path = "/";
              info_type = "available";
              interval = 60;
              warning = 20.0;
              alert = 10.0;
            }
            {
              block = "memory";
              format = " $icon $mem_used_percents ";
            }
            {
              block = "cpu";
              interval = 1;
            }
            {block = "sound";}
            {block = "backlight";}
            {block = "battery";}
            {
              block = "time";
              interval = 60;
              format = " $timestamp.datetime(f:'%a %d/%m %r') ";
            }
          ];
          settings = {
            theme = {
              theme = "gruvbox-dark";
            };
          };
          icons = "awesome5";
          theme = "gruvbox-dark";
        };
      };
      wayland.windowManager.sway = {
        enable = true;
        wrapperFeatures.gtk = true;
        config = {
          inherit modifier;

          input."*" = {
            xkb_options = "caps:escape";
          };
          input."1133:50184:Logitech_USB_Trackball" = {
            scroll_button = "276";
            scroll_method = "on_button_down";
            left_handed = "enabled";
            accel_profile = "flat";
            pointer_accel = "1";
            scroll_factor = "0.5";
          };
          input."1739:31251:DLL07BE:01_06CB:7A13_Touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            middle_emulation = "enabled";
            tap_button_map = "lrm";
            dwt = "enabled";
            click_method = "clickfinger";
          };

          output."*".bg = "${wallpaper} fill";

          startup = [
            {command = "mkfifo $SWAYSOCK.wob && tail -f $SWAYSOCK.wob | ${pkgs.wob}/bin/wob";}
            {command = "${pkgs.mako}/bin/mako";}
            {command = "${pkgs.autotiling}/bin/autotiling";}
            {command = "${pkgs.wl-clipboard}/bin/wl-paste -t text --watch ${pkgs.clipman}/bin/clipman store";}
            {command = "${pkgs.wl-clipboard}/bin/wl-paste -p -t text --watch ${pkgs.clipman}/bin/clipman store -P --histpath='~/.local/share/clipman-primary.json'";}
          ];

          window.titlebar = false;
          workspaceAutoBackAndForth = true;
          defaultWorkspace = "workspace number 1";

          keybindings = let
            super = "Mod4";
          in
            mkOptionDefault {
              # Basic
              "${modifier}+Return" = "exec ${terminal}";
              "${modifier}+Shift+Return" = "exec ${web}";
              "${modifier}+Escape" = "kill";
              "Control+Space" = "exec ${pkgs.mako}/bin/makoctl dismiss";

              # Monitors
              "${modifier}+Control+${left}" = "move workspace to output eDP-1";
              "${modifier}+Control+${right}" = "move workspace to output 'Dell Inc. DELL E2210H P875P0811GHL'";
              "${super}+d" = "output * dpms off";
              "${super}+shift+d" = "output * dpms on";

              # Alt-tab
              "${modifier}+tab" = "workspace back_and_forth";

              # Brightness control
              "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
              "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
              "Shift+XF86MonBrightnessUp" = "exec brightnessctl set +1%";
              "Shift+XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

              # Volume control
              "XF86AudioRaiseVolume" = "exec amixer sset Master 5%+ | sed -En 's/.*\[([0-9]+)%\].*/\1/p' | head -1 > $SWAYSOCK.wob";
              "XF86AudioLowerVolume" = "exec amixer sset Master 5%- | sed -En 's/.*\[([0-9]+)%\].*/\1/p' | head -1 > $SWAYSOCK.wob";
              "XF86AudioMute" = "exec amixer sset Master toggle | sed -En '/\[on\]/ s/.*\[([0-9]+)%\].*/\1/ p; /\[off\]/ s/.*/0/p' | head -1 > $SWAYSOCK.wob";

              # Special Stuff
              "${super}+Delete" = "mode 'System (l) lock, (e) logout, (s) suspend, (h) hibernate, (r) reboot, (Shift+s) shutdown'";
              # "${super}+v" = "exec ${pkgs.clipman}/bin/clipman pick -t wofi";
              # "${super}+period" = "exec launch-rofimoji";
              "Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify save area";
              "Shift+Print" = "exec ${pkgs.sway-contrib.grimshot}/bin/grimshot --notify copy area";
            };

          floating.criteria = [
            {app_id = "^launcher$";}
            {title = "^Picture-in-Picture$";}
            {window_role = "pop-up";}
            {title = "zoom_linux_float_message_reminder";}
            {window_role = "bubble";}
            {title = "Bitwarden — Mozilla Firefox";}
            {window_role = "Open Files";}
            {window_role = "File Operation Progress";}
            {window_role = "Save As";}
            {window_type = "menu";}
          ];
          window.commands = [
            {
              command = "border none";
              criteria.app_id = "qutebrowser";
            }
            {
              command = "sticky enable";
              criteria.title = "Picture-in-Picture";
            }
            {
              criteria.app_id = "^launcher$";
              command = "sticky enable";
            }
            {
              criteria.app_id = "^launcher$";
              command = "resize set 30 ppt 60 ppt";
            }
            {
              criteria.app_id = "^launcher$";
              command = "border pixel 10";
            }
          ];

          modes = mkOptionDefault {
            "System (l) lock, (e) logout, (s) suspend, (h) hibernate, (r) reboot, (Shift+s) shutdown" = {
              "l" = "exec --no-startup-id ${pkgs.swaylock}/bin/swaylock & sleep 1, mode 'default'";
              "e" = "exec --no-startup-id i3-msg exit, mode 'default'";
              "s" = "exec --no-startup-id ${pkgs.swaylock}/bin/swaylock && systemctl suspend, mode 'default'";
              "h" = "exec --no-startup-id ${pkgs.swaylock}/bin/swaylock && systemctl hibernate, mode 'default'";
              "r" = "exec --no-startup-id systemctl reboot, mode 'default'";
              "Shift+s" = "exec --no-startup-id systemctl poweroff -i, mode 'default'";
              "Return" = "mode default";
              "Escape" = "mode default";
            };
          };

          colors = {
            focused = {
              border = colors.light_blue;
              background = colors.light_blue;
              text = colors.normal_black;
              indicator = colors.light_blue;
              childBorder = colors.light_blue;
            };
            focusedInactive = {
              border = colors.bright_gray;
              background = colors.bright_gray;
              text = colors.bright_white;
              indicator = colors.bright_gray;
              childBorder = colors.normal_black;
            };
            unfocused = {
              border = colors.normal_gray;
              background = colors.normal_gray;
              text = colors.normal_white;
              indicator = colors.normal_gray;
              childBorder = colors.normal_black;
            };
            urgent = {
              border = colors.bright_red;
              background = colors.bright_red;
              text = colors.normal_black;
              indicator = colors.unused;
              childBorder = colors.unused;
            };
            placeholder = {
              border = colors.unused;
              background = colors.unused;
              text = colors.unused;
              indicator = colors.unused;
              childBorder = colors.unused;
            };
          };

          fonts = {
            names = ["Atkinson Hyperlegible" "Iosevka Nerd Font"];
            size = 10.0;
          };

          bars = [
            rec {
              position = "bottom";

              fonts = {
                names = ["Atkinson Hyperlegible"];
                size = 10.0;
              };

              statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs ${config.xdg.configHome}/i3status-rust/config-${position}.toml";

              colors = {
                background = "#1d2021";
                inactiveWorkspace = {
                  background = "#282828";
                  border = "#282828";
                  text = "#ebdbb2";
                };
                activeWorkspace = {
                  background = "#282828";
                  border = "#282828";
                  text = "#ebdbb2";
                };
                focusedWorkspace = {
                  background = "#83a598";
                  border = "#83a598";
                  text = "#282828";
                };
                urgentWorkspace = {
                  background = "#cc241d";
                  border = "#cc241d";
                  text = "#282828";
                };
              };
            }
          ];

          gaps.smartBorders = "on";
        };
      };

      # Lock Screen
      services.swayidle = with pkgs; {
        events = [
          {
            event = "before-sleep";
            command = lock-command;
          }
          {
            event = "lock";
            command = lock-command;
          }
        ];
        timeouts = [
          {
            timeout = 330;
            command = lock-command;
          }
          {
            timeout = 330;
            command = "${sway}/bin/swaymsg 'output * dpms off'";
            resumeCommand = "${sway}/bin/swaymsg 'output * dpms on'";
          }
        ];
      };

      # Notifications
      services.mako = {
        enable = true;
        anchor = "bottom-right";
        backgroundColor = colors.normal_black;
        borderColor = colors.normal_white;
        borderSize = 4;
        textColor = colors.normal_white;
        font = "Victor Mono";
        margin = "16";
        padding = "8";
      };

      # Auto log-in
      programs.fish.loginShellInit =
        lib.mkBefore
        ''
          if test (tty) = /dev/tty1
            exec sway &> /dev/null
          end
        '';
      programs.bash.profileExtra =
        lib.mkBefore
        ''
          if [[ "$(tty)" == /dev/tty1 ]]; then
            exec sway &> /dev/null
          fi
        '';
      programs.zsh.loginExtra =
        lib.mkBefore
        ''
          if [[ "$(tty)" == /dev/tty1 ]]; then
            exec sway &> /dev/null
          fi
        '';

      # Misc
      home.sessionVariables = {
        XDG_CURRENT_DESKTOP = "sway";
      };

      # XDG Stuff
      xdg.enable = true;
    };
  };
}
