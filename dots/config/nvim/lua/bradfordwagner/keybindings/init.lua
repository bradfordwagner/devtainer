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

-- lightspeed.vim
-- https://github.com/ggandor/lightspeed.nvim
-- :h lightspeed-custom-mappings
map_key(n_v, 'zj', '<Plug>Lightspeed_s', default_settings)
map_key(n_v, 'zk', '<Plug>Lightspeed_S', default_settings)
map_key(n_v, 'f', '<Plug>Lightspeed_f', default_settings)
map_key(n_v, 'F', '<Plug>Lightspeed_F', default_settings)
map_key(n_v, 't', '<Plug>Lightspeed_t', default_settings)
map_key(n_v, 'T', '<Plug>Lightspeed_T', default_settings)

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
  ['<space>zx'] = { '<cmd>Goyo!<cr><cmd>! tmux resize-pane -Z<cr>' , 'Exit Goyo, Tmux Fullscreen' },
  ['<space>zz'] = { '<cmd>Goyo<cr>' , 'Goyo Toggle, Tmux Fullscreen' },
  ['<space>z'] = { 'Zoom' },
  ['<space>as'] = { '<cmd>Windows<cr>', 'select window' },

  -- maybe change binding later
  ['ZA'] = { '<cmd>update<cr>', 'S(A)ve Current File' },
  ['ZD'] = { '<cmd>r !date<cr>', 'Insert (D)ate' },
  ['ZR'] = { '<cmd>Restart<cr><cmd>source $MYVIMRC<cr><cmd>noh<cr><cmd>CocRestart<cr>', 'Restart' },
  ['Q'] = { '<cmd>q!<cr>', 'Quit' },
  ['ZP'] = { '<cmd>set paste<cr>', '' },
  ['Zp'] = { '<cmd>set nopaste<cr>', ''},
  ['<C-n>'] = { '<cmd>NvimTreeToggle<cr>', '' },
  ['<leader>r'] = { '<cmd>NvimTreeFindFile<cr>', '' },
  ['<C-p>'] = { '<cmd>FZF<cr>', '' },
  ['<C-M-p>'] = { '<cmd>GFiles<cr>', '' },
  ['<leader>w'] = { '<cmd>FZF ~/workspace<cr>', '' },
  ['<leader>c'] = { '<cmd>FZF ~/workspace/github/bradfordwagner/src/bradfordwagner.src.cheatsheet<cr>', '' },
  ['<leader>d'] = { '<cmd>FZF ~/.dotfiles<cr>', '' },

  ['ZSY'] = { '<cmd>set syntax=yaml<cr>', '' },
  ['ZSH'] = { '<cmd>set syntax=helm<cr>', '' },
  ['ZSB'] = { '<cmd>set syntax=bash<cr>', '' },
  ['ZGB'] = { '<cmd>Git blame<cr>', '' },
  ['ZL'] = { '<cmd>!zsh -lc cl<cr><cr>', '' },
  ['Zr'] = { '<cmd>registers<cr>', '' },
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
local dapgo = require('dap-go')
vim.keymap.set("n", "<leader>dt", dapgo.debug_test)
vim.keymap.set("n", "<leader>dl", dapgo.debug_last_test)
wk.register({
  ['<space>s'] = { name = 'Debugger (dap)' },
  ['<space>st'] = { dapui.toggle, 'toggle dap ui' },
})

-- go auto local leader commands
vim.cmd ([[
augroup myGolang
    " delete old aut commands
    au!
    function! s:my_go_bindings()
      nmap <buffer> <LocalLeader>a :echo "hi friends"<cr>
    endfunction
    autocmd FileType go call s:my_go_bindings()
augroup END
]])
