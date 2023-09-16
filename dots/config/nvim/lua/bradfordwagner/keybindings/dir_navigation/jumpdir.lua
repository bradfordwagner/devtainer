-- setup jumpdir configuration for easy pick

-- imports
local cd_action = require 'bradfordwagner.keybindings.dir_navigation.cd_action'.cd_action

-- init return
local M = {}
M.cd  = {
  name = "jumpdir",
  command = "zsh -lc jdl",
  action = cd_action(),
  opts = require('telescope.themes').get_dropdown({}),
}
return M
