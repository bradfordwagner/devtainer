-- telescope keybindings
local builtin = require 'telescope.builtin'

local wk = require 'which-key'
wk.register({
  ['<space>dt'] = { '<cmd>Telescope<cr>', '' },
  ['<space>dpl'] = { builtin.find_files, '' },
  ['<space>dpf'] = { builtin.live_grep, '' },
  ['<space>dpw'] = { builtin.grep_string, '' },
  ['<space>dbf'] = { builtin.current_buffer_fuzzy_find, '' },
  ['<space>dbl'] = { builtin.buffers, '' },
  ['<space>dgl'] = { builtin.git_files, '' },
  ['<space>dbc'] = { builtin.git_bcommits, '' },
  ['<space>dc'] = { builtin.commands, '' },
  ['<space>dm'] = { builtin.keymaps, '' },
})
