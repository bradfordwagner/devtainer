-- setup ag configuration

-- imports
local util = require 'bradfordwagner.util'
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local function action_handler(name_to_command)
  return function(prompt_bufnr, _)
    local function f()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      local val = selection[1]
      local res = name_to_command[val]
      if type(res) == "function" then
        res()
      elseif type(res) == "string" then
        vim.cmd(res)
      end
    end
    actions.select_default:replace(f)
    return true
  end
end

-- init return
local M = {}
function M.setup(config)
  local keys = util.table_map(config.picker_options, 'name')
  local picker_options = '<<EOF\n' .. util.reduce(keys, '\n') .. '\nEOF'

  local name_to_command = {}
  for i,v in ipairs(config.picker_options) do
    name_to_command[v.name] = v.cmd
  end

  return {
    name = config.name,
    command = "cat " .. picker_options,
    action = action_handler(name_to_command),
    opts = require('telescope.themes').get_dropdown({
      layout_config = util.telescope_layout_config,
    }),
  }
end

return M
