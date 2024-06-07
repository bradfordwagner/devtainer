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
map_key(n_v, 'zh', '<Plug>Lightspeed_omni_s', default_settings)
map_key(n_v, 'zl', '<Plug>Lightspeed_omni_gs', default_settings)
map_key(n_v, 'f', '<Plug>Lightspeed_f', default_settings)
map_key(n_v, 'F', '<Plug>Lightspeed_F', default_settings)
map_key(n_v, 't', '<Plug>Lightspeed_t', default_settings)
map_key(n_v, 'T', '<Plug>Lightspeed_T', default_settings)

-- lua-snip
-- ... or in lua, with a different set of keys: <Ctrl-K> for expanding, <Ctrl-L> for jumping forward, <Ctrl-J> for jumping backward, and <Ctrl-E> for changing the active choice.
-- vim.keymap.set({"i"}, "<C-K>", function() ls.expand() end, {silent = true})
-- vim.keymap.set({"i", "s"}, "<C-L>", function() ls.jump( 1) end, {silent = true})
-- vim.keymap.set({"i", "s"}, "<C-J>", function() ls.jump(-1) end, {silent = true})
-- vim.keymap.set({"i", "s"}, "<C-E>", function()
--   if ls.choice_active() then
--     ls.change_choice(1)
--   end
-- end, {silent = true})


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
  ['<space>F'] = { '<cmd>FzfLua<cr>', 'fzf-lua' },
  -- goyo keymaps
  ['<space>zx'] = { '<cmd>Goyo!<cr><cmd>! tmux resize-pane -Z<cr>' , 'Exit Goyo, Tmux Fullscreen' },
  ['<space>zz'] = { '<cmd>Goyo<cr>' , 'Goyo Toggle, Tmux Fullscreen' },
  ['<space>z'] = { 'Zoom' },
  ['<space>as'] = { '<cmd>AIChat<cr>', 'send to ai chat' },
  ['<space>i'] = { '<cmd>Windows<cr>', 'select window' },
  ['<space>zc'] = { '<cmd>let &scrolloff=999-&scrolloff<CR>', 'toggle auto center cursor' },

  -- maybe change binding later
  ['ZA'] = { '<cmd>update<cr>', 'S(A)ve Current File' },
  ['ZD'] = { '<cmd>r !date<cr>', 'Insert (D)ate' },
  ['Q'] = { '<cmd>q!<cr>', 'Quit' },
  ['<space>q'] = { '<cmd>qa!<cr>', 'Quit All' },
  ['ZP'] = { '<cmd>set paste<cr>', '' },
  ['Zp'] = { '<cmd>set nopaste<cr>', ''},
  ['<C-n>'] = { '<cmd>NvimTreeToggle<cr>', '' },
  ['<leader>r'] = { '<cmd>NvimTreeFindFile<cr>', '' },

  ['ZGB'] = { '<cmd>Git blame<cr>', '' },
  ['ZL'] = { '<cmd>!zsh -lc cl<cr><cr>', '' },
})

require 'bradfordwagner.keybindings.easypick'

-- visual mode
wk.register({
  ['<leader><leader>'] = { '"+y<cr>', 'Yank into System Clipboard' },
  ['<leader><cr>'] = { 'y<cr>:call system("tmux load-buffer -", @0)<cr>', 'Yank into Tmux Buffer' },
  ['<leader>a'] = { ':Align ', 'Align' },
  ['<leader>`'] = { 'y:Rg <c-r>"<cr>', 'Ripgrep Selection' },
  ['<leader>sa'] = { ':%sort u<cr>', 'Sort Ascending' },
  ['<leader>sd'] = { ':%sort! u<cr>', 'Sort Descending' },
  ['<leader>g'] = { function ()
    vim.api.nvim_input('y<cr>')                           -- yank into default register
    vim.api.nvim_input('<cmd>sleep 100m<cr>')             -- need a sleep to let the register get populated
    local input = vim.fn.getreg('"')                      -- get the register
    local cmd = ":! print '" .. input .. "' | pbcopy<cr>" -- send it to pbcopy
    vim.api.nvim_input(cmd)                               -- execute the command
  end, 'Yank into Tmux Buffer Unescaped' },
}, {
  -- options
  mode = 'v'
})

-- new stuff
local builtin = require 'telescope.builtin'
local oil = require 'oil'
local ls = require 'luasnip'
wk.register({
  -- base helpers
  ['<space>dt'] = { builtin.builtin, '' },
  ['<space>d/'] = { builtin.help_tags, '' },
  ['<space>d;'] = { builtin.command_history, '' },
  ['<space>ds'] = { builtin.treesitter, '' },
  ['<space><space>'] = { oil.open, 'oil'},
  -- files
  ['<space>f'] = { '<cmd>Easypick files<cr>', 'file finder' },
  -- buffers
  ['<space>dd'] = { '<cmd>Easypick buffers<cr>', 'Buffers' },
  ['<space>o']  = { builtin.buffers, 'Buffers History' },
  -- ag
  ['<space>da'] = { '<cmd>Easypick find<cr>', 'Find' },
  -- misc
  ['<space>dc'] = { builtin.commands, '' },
  ['<space>dm'] = { builtin.keymaps, '' },
  -- jumpdir - shares <space>f with vims 'cd'
  ['<space>df'] = { '<cmd>Easypick dirs<cr>', '' },
  ['<space>dg'] = { '<cmd>Easypick vimgrep<cr>', '' },
  -- scissors/snippets
  ['<space>;'] = { name = 'Snippets' },
  ['<space>;e'] = { function() require("scissors").editSnippet() end, 'scissors edit snippet' },
  ['<space>;E'] = { function() require("scissors").addNewSnippet() end, 'scissors add snippet' },
  ['<space>;a'] = { function() ls.expand() end, {silent = true}, 'expand' },
  ['<space>;j'] = { function() ls.jump( 2) end, {silent = true}, 'next var' },
  ['<space>;k'] = { function() ls.jump(-1) end, {silent = true}, 'prev var' },
  ['<space>;;'] = { '<cmd>Telescope luasnip<cr>', 'select a snippet' },
})

-- dap debugger configuration
local dapui = require 'dapui'
local dap = require 'dap'
local dapgo = require('dap-go')
vim.keymap.set("n", "<leader>dt", dapgo.debug_test)
vim.keymap.set("n", "<leader>dl", dapgo.debug_last_test)
wk.register({
  ['<space>s'] = { name = 'Debugger (dap)' },
  -- toggle ui
  ['<space>sa'] = { function() dapui.toggle(2) end, 'toggle bottom ui' },
  ['<space>sA'] = { dapui.close, 'close ui' },
  ['<space>sr'] = { dapui.toggle, 'toggle ui' },
  ['<space>sv'] = { function() dapui.float_element('scopes') end, 'toggle ui' },
  ['<space>sb'] = { function ()
      vim.api.nvim_input('<space>sv')
      vim.api.nvim_input('<cmd>sleep 25m<cr>')
      vim.api.nvim_input('<space>sv')
      vim.api.nvim_input('<cmd>sleep 25m<cr>')
      vim.api.nvim_input('<space>zz')
    end , 'fullscreen scopes'},
  -- run/debug
  ['<space>ss'] = { dap.continue, 'start/continue' },
  ['<space>sx'] = { dap.terminate, 'terminate' },
  ['<space>sd'] = { dap.run_last, 'run last' },
  -- breakpoints
  ['<space>sh'] = { dap.toggle_breakpoint, 'toggle breakpoint' },
  -- step functions
  ['<space>sj'] = { dap.step_over, 'step over' },
  ['<space>sk'] = { dap.step_out, 'step out' },
  ['<space>sl'] = { dap.step_into, 'step into' },
})

-- go auto local leader commands
vim.cmd ([[
augroup myGolang
    " delete old aut commands
    au!
    function! s:my_go_bindings()
      " yes the space is intentional
      nmap <buffer> <LocalLeader>i :GoImport 
      nmap <buffer> <LocalLeader>I :GoImport! 
      nmap <buffer> <LocalLeader>w :GoTestPkg<cr>
      nmap <buffer> <LocalLeader>t mP<cr>:lua require('dap-go').debug_test()<cr>
      nmap <buffer> <LocalLeader>r `P:lua require('dap-go').debug_test()<cr><C-o>
      nmap <buffer> <LocalLeader>fs :GoFillStruct<cr>
      nmap <buffer> <LocalLeader>fs :GoFillStruct<cr>
      nmap <buffer> <LocalLeader>R :GoRename 
      " add := to the beggining of the line and go to insert mode
      nmap <buffer> <LocalLeader>= Ia := <Esc>0ws
      nmap <buffer> <LocalLeader>- Ia = <Esc>0ws
      nmap <buffer> gd :vsp<cr>:GoDef<CR>
      nmap <buffer> gD :vsp<cr>:GoDefType<CR>
    endfunction
    autocmd FileType go call s:my_go_bindings()
augroup END
]])
