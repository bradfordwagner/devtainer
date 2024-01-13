-- init telescope - this can't be default forever right?
local telescope = require 'telescope'

-- enable multi multi_selection
-- https://github.com/nvim-telescope/telescope.nvim/issues/1048#issuecomment-1220846367
local action_state = require('telescope.actions.state')
local actions = require("telescope.actions")
local transform_mod = require("telescope.actions.mt").transform_mod
local function multiopen(prompt_bufnr, method)
    local cmd_map = {
        vertical = "vsplit",
        horizontal = "split",
        tab = "tabe",
        default = "edit"
    }
    local picker = action_state.get_current_picker(prompt_bufnr)
    local multi_selection = picker:get_multi_selection()

    if #multi_selection > 1 then
        require("telescope.pickers").on_close_prompt(prompt_bufnr)
        pcall(vim.api.nvim_set_current_win, picker.original_win_id)

        for i, entry in ipairs(multi_selection) do
            -- opinionated use-case
            local cmd = i == 1 and "edit" or cmd_map[method]
            vim.cmd(string.format("%s %s", cmd, entry.value))
        end
    else
        actions["select_" .. method](prompt_bufnr)
    end
end

local custom_actions = transform_mod({
    multi_selection_open_vertical = function(prompt_bufnr)
        multiopen(prompt_bufnr, "vertical")
    end,
    multi_selection_open_horizontal = function(prompt_bufnr)
        multiopen(prompt_bufnr, "horizontal")
    end,
    multi_selection_open_tab = function(prompt_bufnr)
        multiopen(prompt_bufnr, "tab")
    end,
    multi_selection_open = function(prompt_bufnr)
        multiopen(prompt_bufnr, "default")
    end,
})

local function stopinsert(callback)
    return function(prompt_bufnr)
        vim.cmd.stopinsert()
        vim.schedule(function()
            callback(prompt_bufnr)
        end)
    end
end
--- end of custom actions

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ["<esc>"] = actions.close,
        ["<c-a>"] = actions.toggle_all,
        ["<c-s>"] = actions.toggle_selection,
        ["<c-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
        ["<c-l>"] = stopinsert(custom_actions.multi_selection_open_vertical),
        ["<c-k>"] = stopinsert(custom_actions.multi_selection_open_horizontal),
        ["<c-i>"] = stopinsert(custom_actions.multi_selection_open_tab),
        ["<cr>"]  = stopinsert(custom_actions.multi_selection_open)
      },
    },
  },
  pickers = {
    buffers = {
      mappings = {
        i = {
          ["<c-d>"] = actions.delete_buffer + actions.move_to_top,
        }
      }
    }
  }
}

-- https://github.com/nvim-telescope/telescope-fzf-native.nvim
require('telescope').load_extension('fzf')
require('telescope').load_extension('luasnip')
