-- setup easy pick
-- https://github.com/axkirillov/easypick.nvim/wiki
local easypick = require 'easypick'
local jumpdir = require 'bradfordwagner.keybindings.dir_navigation.jumpdir'
local finddir = require 'bradfordwagner.keybindings.dir_navigation.finddir'
local wdfinddir = require 'bradfordwagner.keybindings.dir_navigation.wdfinddir'
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

