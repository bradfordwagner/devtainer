-- setup jumpdir configuration for easy pick

-- imports
local easypick = require 'easypick'
local cd_action = require 'bradfordwagner.keybindings.dir_navigation.cd_action'.cd_action

-- init return
local M = {}
M.cd  = {
  name = "jumpdir",
  command = "zsh -lc jdl",
  previewer = easypick.previewers.default(),
  action = cd_action(),
}
return M
