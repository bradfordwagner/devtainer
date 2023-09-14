-- setup finddir configuration for easy pick

-- imports
local easypick = require 'easypick'
local cd_action = require 'bradfordwagner.keybindings.cd_action'.cd_action


-- init return
local M = {}
M.fd  = {
  name = "finddir",
  -- command = "find . -type d",
  command = "find . -mindepth 1 -type d \\( -name '.*' -prune -o -print \\)",
  previewer = easypick.previewers.default(),
  action = cd_action(),
}
return M
