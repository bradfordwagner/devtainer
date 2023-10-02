-- global --------------------------------------------------
-- set up leaders
vim.g.maploader = '\\'
vim.g.maplocalloader = ','

vim.g.vim_json_conceal = 0
-- vim rooter to manual mode
vim.g.rooter_manual_only = 1

-- lightspeed-disable-default-mappings
-- must be loaded before lightspeed.vim
vim.g.lightspeed_no_default_keymaps = 1

-- vim.g.copilot_assume_mapped = true
-- vim.g.copilot_no_tab_map = true
--
        -- imap <silent><script><expr> <C-J> copilot#Accept("\<CR>")
        -- let g:copilot_no_tab_map = v:true
-- end global ----------------------------------------------


-- options -------------------------------------------------
vim.o.scrolloff = 999 -- auto center cursor
vim.o.mouse = '' -- disable mouse
vim.o.number = true
-- vim.o.relativenumber = true
-- end options ---------------------------------------------

-- gofmt on save -------------------------------------------
-- https://github.com/ray-x/go.nvim#format-on-save
local format_sync_grp = vim.api.nvim_create_augroup("GoFormat", {})
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function()
   require('go.format').gofmt()
  end,
  group = format_sync_grp,
})
-- end gofmt on save----------------------------------------
