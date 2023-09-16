-- setup finddir configuration for easy pick

-- imports
local easypick = require 'easypick'
local cd_action = require 'bradfordwagner.keybindings.dir_navigation.cd_action'.cd_action

-- init return
local home = vim.fn.getenv('HOME')
local M = {}
M.fd  = {
  name = "workspace_find_dir",
  -- command = "find . -type d",
  command = string.format("find ~/workspace -mindepth 1 -type d \\( -name '.*' -prune -o -print \\) | sed 's|^%s|~|'", home),
  previewer = easypick.previewers.default(),
  action = cd_action(),
}
return M
