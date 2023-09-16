-- setup ag configuration

-- imports
local easypick = require 'easypick'
local util = require 'bradfordwagner.util'
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local function action_handler(config)
  return function(prompt_bufnr, _)
    local function f()
      actions.close(prompt_bufnr)
      local selection = action_state.get_selected_entry()
      local val = selection[1]
      local res = config.picker_options[val]
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
  -- local config = {
  --   name = 'multi',
  --   picker_options = {
  --     ["f1"] = function () print('a') end,
  --     ["f2"] = function () print('b') end,
  --     ["command"] = 'echo "hi friends"',
  --   }
  -- }
  local keys = util.table_key(config.picker_options)
  local picker_options = '<<EOF\n' .. util.reduce(keys, '\n') .. '\nEOF'

  return {
    name = config.name,
    command = "cat " .. picker_options,
    previewer = easypick.previewers.default(),
    action = action_handler(config),
  }
end

return M
