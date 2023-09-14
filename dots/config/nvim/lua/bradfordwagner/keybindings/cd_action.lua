-- setup jumpdir configuration for easy pick

-- imports
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local M = {}
function M.cd_action()
  return function(prompt_bufnr, _)
    local function f()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      local val = selection[1]
      vim.cmd(string.format('echo "%s"', val))
      vim.cmd(string.format('cd %s', val))
    end

    actions.select_default:replace(f)
    return true
  end
end

return M
