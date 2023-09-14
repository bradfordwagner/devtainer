-- setup easy pick
-- https://github.com/axkirillov/easypick.nvim/wiki
local easypick = require 'easypick'
local jumpdir = require 'bradfordwagner.keybindings.jumpdir'
local finddir = require 'bradfordwagner.keybindings.finddir'

easypick.setup {
  pickers = {
    jumpdir.cd,
    finddir.fd,
  }
}

