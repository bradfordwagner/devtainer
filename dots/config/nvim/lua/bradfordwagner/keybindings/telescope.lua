-- telescope keybindings
local builtin = require 'telescope.builtin'
local wk = require 'which-key'

wk.register({
  -- base helpers
  ['<space>dt'] = { builtin.builtin, '' },
  ['<space>d/'] = { builtin.help_tags, '' },
  ['<space>d;'] = { builtin.command_history, '' },
  -- files
  ['<space>df'] = { '<cmd>Easypick files<cr>', 'file finder' },
  -- project
  ['<space>dpf'] = { builtin.live_grep, '' },
  ['<space>dpw'] = { builtin.grep_string, '' },
  -- buffers
  ['<space>dbf'] = { builtin.current_buffer_fuzzy_find, '' },
  ['<space>dbl'] = { builtin.buffers, '' },
  ['<space>dbc'] = { builtin.git_bcommits, '' },
  -- ag
  ['<space>da'] = { '<cmd>Easypick ag<cr>', 'Ag Silver Searcher' },
  -- misc
  ['<space>dc'] = { builtin.commands, '' },
  ['<space>dm'] = { builtin.keymaps, '' },
  -- jumpdir - shares <space>f with vims 'cd'
  ['<space>fj'] = { '<cmd>Easypick jumpdir<cr>', '' },
  ['<space>fk'] = { '<cmd>Easypick workspace_find_dir<cr>', '' },
  ['<space>fl'] = { '<cmd>Easypick finddir<cr>', '' },
})
