-- setup easy pick
-- https://github.com/axkirillov/easypick.nvim/wiki
local easypick = require 'easypick'
local jumpdir = require 'bradfordwagner.keybindings.jumpdir'
local finddir = require 'bradfordwagner.keybindings.finddir'
local wdfinddir = require 'bradfordwagner.keybindings.wdfinddir'
local ag = require 'bradfordwagner.keybindings.ag'
local files = require 'bradfordwagner.keybindings.files'

easypick.setup {
  pickers = {
    jumpdir.cd,
    finddir.fd,
    wdfinddir.fd,
    ag,
    files,
  }
}

