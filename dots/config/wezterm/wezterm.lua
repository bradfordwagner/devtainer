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
-- config.color_scheme = 'AdventureTime'
config.font = wezterm.font('JetBrains Mono', { weight = 'ExtraBold' })

--
config.window_decorations = "RESIZE | MACOS_FORCE_DISABLE_SHADOW"
config.color_scheme       = "ChallengerDeep"
config.enable_tab_bar     = false
config.window_close_confirmation = "NeverPrompt"
config.font_size          = 12.0

-- and finally, return the configuration to wezterm
return config
