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

-- find current word in current buffer
map_key(n ,'<Space>sbww', ':BLines <c-r><c-w><CR>', default_settings)
map_key(n, '<Space>sbwe', ':BLines <c-r><c-a><CR>', default_settings)

-- which-key
vim.o.timeout = true
vim.o.timeoutlen = 300
local wk = require 'which-key'
wk.setup {
  window = {
    border = "single", -- none, single, double, shadow
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
  ['<space>sb'] = { name = 'Buffers' },
  ['<space>sba'] = { '<cmd>Lines<cr>', 'Find in ALL' },
  ['<space>sbd'] = { '<cmd>BD<cr>', 'Delete' },
  ['<space>sbf'] = { '<cmd>BLines<cr>', 'Find Current' },
  ['<space>sbl'] = { '<cmd>Buffers<cr>', 'List' },
  ['<space>sbw'] = { name = "Find Word Under Cursor" },
  ['<space>sbwe'] = { 'Find Current WORD' },
  ['<space>sbww'] = { 'Find Current Word' },
  ['<space>sc'] = { '<cmd>Commands<cr>', 'Commands' },
  -- goyo keymaps
  ['<Space>zx'] = { '<cmd>Goyo!<CR><cmd>! tmux resize-pane -Z<CR>' , 'Exit Goyo, Tmux Fullscreen' },
  ['<Space>zz'] = { '<cmd>Goyo<cr>' , 'Goyo Toggle, Tmux Fullscreen' },
  ['<space>z'] = { 'Zoom' },

  -- maybe change binding later
  ['ZA'] = { '<cmd>update<cr>', 'S(A)ve Current File' },
  ['ZD'] = { '<cmd>r !date<cr>', 'Insert (D)ate' },
  ['ZR'] = { '<cmd>Restart<cr><cmd>source $MYVIMRC<cr><cmd>noh<cr><cmd>CocRestart<cr>', 'Restart' },
  ['Q'] = { '<cmd>q!<cr>', 'Quit' },
  ['ZP'] = { '<cmd>set paste<cr>', '' },
  ['Zp'] = { '<cmd>set nopaste<cr>', ''},
})
