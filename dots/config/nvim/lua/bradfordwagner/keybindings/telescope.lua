-- telescope keybindings
local builtin = require 'telescope.builtin'
local jumpdir = require 'bradfordwagner.keybindings.jumpdir'

local wk = require 'which-key'
wk.register({
  -- base helpers
  ['<space>dt'] = { '<cmd>Telescope<cr>', '' },
  -- project
  ['<space>dpl'] = { builtin.find_files, '' },
  ['<space>dpf'] = { builtin.live_grep, '' },
  ['<space>dpw'] = { builtin.grep_string, '' },
  -- buffers
  ['<space>dbf'] = { builtin.current_buffer_fuzzy_find, '' },
  ['<space>dbl'] = { builtin.buffers, '' },
  ['<space>dbc'] = { builtin.git_bcommits, '' },
  -- git
  ['<space>dgl'] = { builtin.git_files, '' },
  ['<space>dgr'] = { '<cmd>Telescope repo cached_list<cr>', '' },
  -- misc
  ['<space>dc'] = { builtin.commands, '' },
  ['<space>dm'] = { builtin.keymaps, '' },

  -- jumpdir
  ['<space>dj'] = { jumpdir.find_files, '' },

})
