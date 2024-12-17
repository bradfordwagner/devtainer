-- global --------------------------------------------------
-- set up leaders
vim.g.maploader = '\\'
vim.g.maplocalleader = ','

-- treesitter fix markdown ``` hidden
-- https://github.com/nvim-treesitter/nvim-treesitter/issues/3723#issuecomment-1293050165
-- vim.g.conceallevel = 0

vim.g.vim_json_conceal = 0
-- vim rooter to manual mode
vim.g.rooter_manual_only = 1

-- lightspeed-disable-default-mappings
-- must be loaded before lightspeed.vim
vim.g.lightspeed_no_default_keymaps = 1

-- bookmarks - https://github.com/MattesGroeger/vim-bookmarks
-- do not globally save bookmarks
vim.g.bookmark_save_per_working_dir = 1
-- end global ----------------------------------------------


-- options -------------------------------------------------
vim.o.scrolloff = 999 -- auto center cursor
vim.o.mouse = '' -- disable mouse
vim.o.number = true
-- vim.o.relativenumber = true
-- end options ---------------------------------------------

-- cmd -----------------------------------------------------
vim.api.nvim_create_user_command('AutocommandObsession',
  function ()
    vim.cmd [[ autocmd VimEnter * Obsession session.vim ]]
  end, {}
)
-- end cmd--------------------------------------------------

