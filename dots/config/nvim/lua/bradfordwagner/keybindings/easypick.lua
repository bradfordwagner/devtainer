-- setup easy pick
-- https://github.com/axkirillov/easypick.nvim/wiki


-- a list of commands that you want to pick from
local list = [[
<< EOF
:PackerInstall
:Telescope find_files
:Git blame
EOF
]]


local easypick = require 'easypick'
local jumpdir = require 'bradfordwagner.keybindings.jumpdir'
easypick.setup {
  pickers = {
    jumpdir.cd,
    {
      name = "finder",
      command = "cat " .. list,
      -- pass a pre-configured action that runs the command
      action = easypick.actions.nvim_command(),
      -- you can specify any theme you want, but the dropdown looks good for this example =)
      opts = require('telescope.themes').get_dropdown({})
    }
  }
}

