-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
-- wezterm ls-fonts --list-system | grep -i Iosevka | grep -i extrabold
config.font = wezterm.font("JetBrains Mono", { weight = "ExtraBold" })
config.font = wezterm.font("IosevkaTerm Nerd Font Mono", {weight="ExtraBold"})

--
config.window_decorations        = "RESIZE | MACOS_FORCE_DISABLE_SHADOW"
config.color_scheme              = "Tokyo Night Moon" -- "Tokyo Night|ChallengerDeep|GruvboxDarkHard|One Half Black (Gogh)|Modus-Vivendi"
config.colors = {
  background = 'black',
}
config.enable_tab_bar            = false
config.window_close_confirmation = "NeverPrompt"
config.font_size                 = 12.0
config.audible_bell              = "Disabled"

-- window border
local border_color = '#3578F7'
-- local border_color = '#565575'
config.window_frame = {
  border_left_width    = '0.3cell',
  border_right_width   = '0.3cell',
  border_bottom_height = '0.2cell',
  border_top_height    = '0.2cell',
  border_left_color    = border_color,
  border_right_color   = border_color,
  border_bottom_color  = border_color,
  border_top_color     = border_color,
}

-- and finally, return the configuration to wezterm
return config
