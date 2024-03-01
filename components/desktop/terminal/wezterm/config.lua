local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Gruvbox Dark (Gogh)'

config.font = wezterm.font 'Iosevka Nerd Font'
config.hide_tab_bar_if_only_one_tab = true
config.front_end = "WebGpu"
config.tiling_desktop_environments = {
    'Wayland',
    'X11 LG3D',
    'X11 bspwm',
    'X11 i3',
    'X11 dwm',
}
config.window_close_confirmation = "NeverPrompt"


return config
