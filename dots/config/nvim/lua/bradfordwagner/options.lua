-- global --------------------------------------------------
-- set up leaders
vim.g.maploader = '\\'
vim.g.maplocalleader = ','

vim.g.vim_json_conceal = 0
-- vim rooter to manual mode
vim.g.rooter_manual_only = 1

-- lightspeed-disable-default-mappings
-- must be loaded before lightspeed.vim
vim.g.lightspeed_no_default_keymaps = 1
-- end global ----------------------------------------------


-- options -------------------------------------------------
vim.o.scrolloff = 999 -- auto center cursor
vim.o.mouse = '' -- disable mouse
vim.o.number = true
-- vim.o.relativenumber = true
-- end options ---------------------------------------------
