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

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
