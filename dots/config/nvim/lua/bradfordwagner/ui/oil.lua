-- https://github.com/stevearc/oil.nvim#quick-start
local actions = require('oil.actions')
local oil = require('oil')

local function reset_window_focus()
  vim.api.nvim_input('<cmd>sleep 50m<cr>')
  vim.api.nvim_input('<C-w><C-p>')
end

require("oil").setup({
  keymaps = {
    ["<C-l>"] = { callback = function ()
      oil.select({vertical = true})
      reset_window_focus()
    end },
    ["<C-k>"] = { callback = function ()
      oil.select({horizontal = true})
      reset_window_focus()
    end },
    ["<C-i>"] = { callback = function ()
      oil.select({tab = true})
      reset_window_focus()
    end },
  }
})
