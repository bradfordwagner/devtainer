-- setup finddir configuration for easy pick

-- imports
local cd_action = require 'bradfordwagner.keybindings.dir_navigation.cd_action'.cd_action
local util = require 'bradfordwagner.util'

-- init return
local M = {}
M.fd  = {
  name = "finddir",
  command = "find . -mindepth 1 -type d \\( -name '.*' -prune -o -print \\)",
  action = cd_action(),
  opts = require('telescope.themes').get_dropdown({
      layout_config = util.telescope_layout_config,
  }),
}
return M
