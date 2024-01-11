-- install https://github.com/folke/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- setup
vim.g.mapleader = ' '
require("lazy").setup({
  'folke/which-key.nvim',

  -- ui
  -- telescope
  'nvim-telescope/telescope.nvim',
  { 'nvim-telescope/telescope-fzf-native.nvim', build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' },
  -- for easy custom picker configuration
  { 'axkirillov/easypick.nvim', dependencies = 'nvim-telescope/telescope.nvim' },
  -- end telescope
  -- dap debugger
  'mfussenegger/nvim-dap', -- https://github.com/mfussenegger/nvim-dap
  'rcarriga/nvim-dap-ui',  -- https://github.com/rcarriga/nvim-dap-ui
  'leoluz/nvim-dap-go',    -- https://github.com/leoluz/nvim-dap-go
  -- go config
  'ray-x/go.nvim',
  'ray-x/guihua.lua', -- recommended if need floating window support
  -- oil
  "stevearc/oil.nvim",
  -- rainbow delims
  "HiPhish/rainbow-delimiters.nvim",
  { 'echasnovski/mini.nvim', branch = 'stable' }, -- https://github.com/echasnovski/mini.nvim
  -- color scheme
  { 'miikanissi/modus-themes.nvim', lazy = false },

  -- jump
  'ggandor/lightspeed.nvim',

  -- utility
  -- change project directory
  'airblade/vim-rooter',
  -- reload nvim configuration
  { 'famiu/nvim-reload', dependencies = { 'nvim-lua/plenary.nvim' } },

  -- vundle plugins
  'leafgarland/typescript-vim',
  'ryanoasis/vim-devicons',
  'towolf/vim-helm',
  'junegunn/goyo.vim',
  'airblade/vim-gitgutter',
  'ntpeters/vim-better-whitespace',      -- shows trailing whitespace
  'tpope/vim-surround',
  'vim-scripts/Align',
  'mattesgroeger/vim-bookmarks',
  'auwsmit/vim-active-numbers',          -- show numbers in gutter from 0 current line up and down
  'tpope/vim-commentary',
  'christianrondeau/vim-base64',         -- used for base64 easy encoding wahoo
  'tpope/vim-tbone',                     -- lets us do our tmux yank - super important
  'tpope/vim-fugitive',                  -- helps with git commands, blame, etc https://github.com/tpope/vim-fugitive
  'hashivim/vim-terraform',              -- terraform support with completion of sub commands - https://github.com/hashivim/vim-terraform
  'challenger-deep-theme/vim',           -- {'name': 'challenger-deep-theme'} " https://github.com/challenger-deep-theme/vim
  'christoomey/vim-tmux-navigator',      -- https://github.com/christoomey/vim-tmux-navigator
  'yggdroot/indentline',                 -- https://github.com/yggdroot/indentline
  -- 'rrethy/vim-illuminate',               -- https://github.com/RRethy/vim-illuminate - highlights word under cursor
  'raimondi/delimitmate',                -- auto close brackets, quotes, etc
  'tpope/vim-obsession',                 -- https://github.com/tpope/vim-obsession
  -- markdown support
  'godlygeek/tabular',
  'preservim/vim-markdown',

  -- vim-plug
  { 'junegunn/fzf', build = ":call fzf#install()" },
  'junegunn/fzf.vim',
  'ghifarit53/tokyonight-vim', -- color scheme
  'kmonad/kmonad-vim',
  'tpope/vim-sleuth',            -- indentation
  'norcalli/nvim-colorizer.lua', -- https://github.com/norcalli/nvim-colorizer.lua
  'pearofducks/ansible-vim',
  'TamaMcGlinn/quickfixdd',      -- allows deleting entries in quickfix list using dd - https://github.com/TamaMcGlinn/quickfixdd
  'madox2/vim-ai',               -- open ai integration: https://github.com/madox2/vim-ai
  'tribela/vim-transparent',     -- https://github.com/tribela/vim-transparent - enable transparency
  'folke/noice.nvim',        -- https://github.com/folke/noice.nvim - replaces messages, cmdline, popupmenu
  'MunifTanjim/nui.nvim',    -- required by noice
  'rcarriga/nvim-notify',    -- https://github.com/rcarriga/nvim-notify - pretty notifications
  -- lualine: https://github.com/nvim-lualine/lualine.nvim#installation
  'nvim-lualine/lualine.nvim',
  -- If you want to have icons in your statusline choose one of these
  'nvim-tree/nvim-web-devicons',
  'nvim-tree/nvim-tree.lua', -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Installation
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- calling `setup` is optional for customization
      require("fzf-lua").setup({})
    end
  },
  {'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons'},
  {'fatih/vim-go', build = ':GoUpdateBinaries' },
  {'neoclide/coc.nvim', branch = 'release' },
})
