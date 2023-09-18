-- setup easy pick
-- https://github.com/axkirillov/easypick.nvim/wiki
local easypick = require 'easypick'
-- dir navigation
local jumpdir = require 'bradfordwagner.keybindings.dir_navigation.jumpdir'
local finddir = require 'bradfordwagner.keybindings.dir_navigation.finddir'
local wdfinddir = require 'bradfordwagner.keybindings.dir_navigation.wdfinddir'
-- consolidated fuzzy finds
local ag = require 'bradfordwagner.keybindings.find'
local files = require 'bradfordwagner.keybindings.files'
local dirs = require 'bradfordwagner.keybindings.dirs'
local buffers = require 'bradfordwagner.keybindings.buffers'
local vimgrep = require 'bradfordwagner.keybindings.vimgrep'

easypick.setup {
  pickers = {
    ag,
    buffers,
    dirs,
    files,
    finddir.fd,
    jumpdir.cd,
    vimgrep,
    wdfinddir.fd,
  }
}
