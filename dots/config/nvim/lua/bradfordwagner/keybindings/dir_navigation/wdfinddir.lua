-- setup workspace_find_dir configuration for easy pick

-- imports
local cd_action = require 'bradfordwagner.keybindings.dir_navigation.cd_action'.cd_action
local util = require 'bradfordwagner.util'

-- init return
local home = vim.fn.getenv('HOME')
local M = {}
M.fd  = {
  name = "workspace_find_dir",
  -- command = "find . -type d",
  command = string.format("find ~/workspace -mindepth 1 -type d \\( -name '.*' -prune -o -print \\) | sed 's|^%s|~|'", home),
  action = cd_action(),
  opts = require('telescope.themes').get_dropdown({
      layout_config = util.telescope_layout_config,
  }),
}
return M
