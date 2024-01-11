-- install https://github.com/wbthomason/packer.nvim

local ensure_packer = function()
  local fn = vim.fn
  local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
  if fn.empty(fn.glob(install_path)) > 0 then
    fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd [[packadd packer.nvim]]
    return true
  end
  return false
end

local packer_bootstrap = ensure_packer()

return require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'
  -- neovim helpers
  use 'folke/which-key.nvim'

  -- ui
  -- telescope
  use "nvim-telescope/telescope.nvim"
  use { 'nvim-telescope/telescope-fzf-native.nvim', run =
  'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build' }
  -- for easy custom picker configuration
  use { 'axkirillov/easypick.nvim', requires = 'nvim-telescope/telescope.nvim' }
  -- end telescope
  -- dap debugger
  use 'mfussenegger/nvim-dap' -- https://github.com/mfussenegger/nvim-dap
  use 'rcarriga/nvim-dap-ui'  -- https://github.com/rcarriga/nvim-dap-ui
  use 'leoluz/nvim-dap-go'    -- https://github.com/leoluz/nvim-dap-go
  -- go config
  use 'ray-x/go.nvim'
  use 'ray-x/guihua.lua' -- recommended if need floating window support
  -- oil
  use "stevearc/oil.nvim"
  -- rainbow delims
  use "HiPhish/rainbow-delimiters.nvim"
  use { 'echasnovski/mini.nvim', branch = 'stable' } -- https://github.com/echasnovski/mini.nvim
  -- color scheme
  use({ "miikanissi/modus-themes.nvim" })

  -- jump
  use 'ggandor/lightspeed.nvim'

  -- utility
  -- change project directory
  use 'airblade/vim-rooter'
  -- reload nvim configuration
  use {
    'famiu/nvim-reload',
    requires = { 'nvim-lua/plenary.nvim' }
  }

  -- vundle plugins
  use 'leafgarland/typescript-vim'
  use 'ryanoasis/vim-devicons'
  use 'towolf/vim-helm'
  use 'junegunn/goyo.vim'
  use 'airblade/vim-gitgutter'
  use 'ntpeters/vim-better-whitespace'      -- shows trailing whitespace
  use 'tpope/vim-surround'
  use 'vim-scripts/Align'
  use 'mattesgroeger/vim-bookmarks'
  use 'auwsmit/vim-active-numbers'          -- show numbers in gutter from 0 current line up and down
  use 'tpope/vim-commentary'
  use 'christianrondeau/vim-base64'         -- used for base64 easy encoding wahoo
  use 'tpope/vim-tbone'                     -- lets us do our tmux yank - super important
  use 'tpope/vim-fugitive'                  -- helps with git commands, blame, etc https://github.com/tpope/vim-fugitive
  use 'hashivim/vim-terraform'              -- terraform support with completion of sub commands - https://github.com/hashivim/vim-terraform
  use 'challenger-deep-theme/vim'           -- {'name': 'challenger-deep-theme'} " https://github.com/challenger-deep-theme/vim
  use 'christoomey/vim-tmux-navigator'      -- https://github.com/christoomey/vim-tmux-navigator
  use 'yggdroot/indentline'                 -- https://github.com/yggdroot/indentline
  use 'rrethy/vim-illuminate'               -- https://github.com/RRethy/vim-illuminate - highlights word under cursor
  use 'raimondi/delimitmate'                -- auto close brackets, quotes, etc
  use 'tpope/vim-obsession'                 -- https://github.com/tpope/vim-obsession
  -- markdown support
  use 'godlygeek/tabular'
  use 'preservim/vim-markdown'

  -- vim-plug
  use { 'junegunn/fzf', run = ":call fzf#install()" }
  use { 'junegunn/fzf.vim' }
  use 'ghifarit53/tokyonight-vim' -- color scheme
  use 'kmonad/kmonad-vim'
  use 'tpope/vim-sleuth'            -- indentation
  use 'norcalli/nvim-colorizer.lua' -- https://github.com/norcalli/nvim-colorizer.lua
  use 'pearofducks/ansible-vim'
  use 'TamaMcGlinn/quickfixdd'      -- allows deleting entries in quickfix list using dd - https://github.com/TamaMcGlinn/quickfixdd
  use 'madox2/vim-ai'               -- open ai integration: https://github.com/madox2/vim-ai
  use 'tribela/vim-transparent'     -- https://github.com/tribela/vim-transparent - enable transparency
  use 'folke/noice.nvim'        -- https://github.com/folke/noice.nvim - replaces messages, cmdline, popupmenu
  use 'MunifTanjim/nui.nvim'    -- required by noice
  use 'rcarriga/nvim-notify'    -- https://github.com/rcarriga/nvim-notify - pretty notifications
  -- lualine: https://github.com/nvim-lualine/lualine.nvim#installation
  use 'nvim-lualine/lualine.nvim'
  -- If you want to have icons in your statusline choose one of these
  use 'nvim-tree/nvim-web-devicons'
  use 'nvim-tree/nvim-tree.lua' -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Installation
  use {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"}
  use {
    "ibhagwan/fzf-lua",
    -- optional for icon support
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      -- calling `setup` is optional for customization
      require("fzf-lua").setup({})
    end
  }
  use {'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons'}
  use {'fatih/vim-go', build = ':GoUpdateBinaries' }


  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
