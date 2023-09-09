-- For key mappings for all modes.
local all_modes = { 'n', 'i', 'v', 't' }
local exclude_t = { 'n', 'i', 'v' }
local exclude_i  = { 'n', 'v', 't' }
local n_v = { 'n', 'v' }
local n_t = { 'n', 't' }
local n = 'n'

-- Function to map keys.
local map_key = vim.keymap.set
-- Default config for the keymaps.
local default_settings = {
  noremap = true,
  silent = true,
}

-- goyo keymaps
map_key(n, '<Space>zz', '<cmd>Goyo<cr>', default_settings)
map_key(n, '<Space>zx', '<cmd>Goyo!<CR><cmd>! tmux resize-pane -Z<CR>', default_settings)

-- which-key
vim.o.timeout = true
vim.o.timeoutlen = 300
local wk = require 'which-key'
wk.setup {
  window = {
    border = "shadow", -- none, single, double, shadow
    position = "bottom", -- bottom, top
    margin = { 1, 0, 1, 0 }, -- extra window margin [top, right, bottom, left]. When between 0 and 1, will be treated as a percentage of the screen size.
    padding = { 1, 2, 1, 2 }, -- extra window padding [top, right, bottom, left]
    winblend = 0, -- value between 0-100 0 for fully opaque and 100 for fully transparent
    zindex = 1000, -- positive value to position WhichKey above other floating windows.
  },
}
wk.register({
  ['<space>'] = { name = 'Customized Binds' },
  ['<space>f'] = { '<cmd>FzfLua<cr>', 'fzf-lua' },
  ['<space>s'] = { name = 'Search' },
  ['<space>sb'] = { name = 'buffers' },
  ['<space>sba'] = { '<cmd>Lines<cr>', 'Find ALL' },
  ['<space>sbd'] = { '<cmd>BD<cr>', 'Delete' },
  ['<space>sbf'] = { '<cmd>Blines<cr>', 'Find Current' },
  ['<space>sbl'] = { '<cmd>Buffers<cr>', 'List' },
  ['<space>sbw'] = { name = "Find Word Under Cursor" },
  ['<space>sbwe'] = { '<cmd>BLines <c-r><c-w><cr>', 'Find Current WORD' },
  ['<space>sbww'] = { '<cmd>BLines <c-r><c-w><cr>', 'Find Current Word' },
  ['<space>sc'] = { '<cmd>Commands<cr>', 'Commands' },
})
