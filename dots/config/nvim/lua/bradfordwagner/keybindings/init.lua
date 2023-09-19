-- For key mappings for all modes.
local all_modes = { 'n', 'i', 'v', 't' }
local exclude_t = { 'n', 'i', 'v' }
local exclude_i  = { 'n', 'v', 't' }
local n_v = { 'n', 'v' }
local v = { 'v' }
local n_t = { 'n', 't' }
local n = 'n'

-- Function to map keys.
local map_key = vim.keymap.set
-- Default config for the keymaps.
local default_settings = {
  noremap = true,
  silent = true,
}

-- example in case i ever circle back
-- map_key(n ,'<space>sbww', ':BLines <c-r><c-w><cr>', default_settings)
map_key(v, 'ZSA', ':%sort u<CR>', default_settings)
map_key(v, 'ZSR', ':%sort! u<cr>', default_settings)

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
  ['<space>L'] = { '<cmd>FzfLua<cr>', 'fzf-lua' },
  -- goyo keymaps
  ['<Space>zx'] = { '<cmd>Goyo!<CR><cmd>! tmux resize-pane -Z<CR>' , 'Exit Goyo, Tmux Fullscreen' },
  ['<Space>zz'] = { '<cmd>Goyo<cr>' , 'Goyo Toggle, Tmux Fullscreen' },
  ['<space>z'] = { 'Zoom' },
  ['<space>as'] = { '<cmd>Windows<CR>', 'select window' },

  -- maybe change binding later
  ['ZA'] = { '<cmd>update<cr>', 'S(A)ve Current File' },
  ['ZD'] = { '<cmd>r !date<cr>', 'Insert (D)ate' },
  ['ZR'] = { '<cmd>Restart<cr><cmd>source $MYVIMRC<cr><cmd>noh<cr><cmd>CocRestart<cr>', 'Restart' },
  ['Q'] = { '<cmd>q!<cr>', 'Quit' },
  ['ZP'] = { '<cmd>set paste<cr>', '' },
  ['Zp'] = { '<cmd>set nopaste<cr>', ''},
  ['<C-n>'] = { '<cmd>NvimTreeToggle<CR>', '' },
  ['<leader>r'] = { '<cmd>NvimTreeFindFile<cr>', '' },
  ['<C-p>'] = { '<cmd>FZF<CR>', '' },
  ['<C-M-p>'] = { '<cmd>GFiles<CR>', '' },
  ['<leader>w'] = { '<cmd>FZF ~/workspace<CR>', '' },
  ['<leader>c'] = { '<cmd>FZF ~/workspace/github/bradfordwagner/src/bradfordwagner.src.cheatsheet<CR>', '' },
  ['<leader>d'] = { '<cmd>FZF ~/.dotfiles<CR>', '' },

  ['ZSY'] = { '<cmd>set syntax=yaml<CR>', '' },
  ['ZSH'] = { '<cmd>set syntax=helm<CR>', '' },
  ['ZSB'] = { '<cmd>set syntax=bash<CR>', '' },
  ['ZGB'] = { '<cmd>Git blame<CR>', '' },
  ['ZL'] = { '<cmd>!zsh -lc cl<CR><CR>', '' },
  ['Zr'] = { '<cmd>registers<CR>', '' },
})

require 'bradfordwagner.keybindings.easypick'

-- visual mode
wk.register({
  ['<space>'] = { '"+y<cr>', 'Yank into System Clipboard' },
  ['<cr>'] = { 'y<cr>:call system("tmux load-buffer -", @0)<cr>', 'Yank into Tmux Buffer' },
}, {
  -- options
  mode = 'v'
})

-- new stuff
local builtin = require 'telescope.builtin'
wk.register({
  -- base helpers
  ['<space>dt'] = { builtin.builtin, '' },
  ['<space>d/'] = { builtin.help_tags, '' },
  ['<space>d;'] = { builtin.command_history, '' },
  ['<space>ds'] = { builtin.treesitter, '' },
  -- files
  ['<space>f'] = { '<cmd>Easypick files<cr>', 'file finder' },
  -- buffers
  ['<space>dd'] = { '<cmd>Easypick buffers<cr>', 'Buffers' },
  -- ag
  ['<space>da'] = { '<cmd>Easypick find<cr>', 'Find' },
  -- misc
  ['<space>dc'] = { builtin.commands, '' },
  ['<space>dm'] = { builtin.keymaps, '' },
  -- jumpdir - shares <space>f with vims 'cd'
  ['<space>df'] = { '<cmd>Easypick dirs<cr>', '' },
  ['<space>dg'] = { '<cmd>Easypick vimgrep<cr>', '' },
})
-- dap debugger configuration
local dapui = require 'dapui'
wk.register({
  ['<space>s'] = { name = 'Debugger (dap)' },
  ['<space>st'] = { dapui.toggle, 'toggle dap ui' },
})
