local dapui = require("dapui")
dapui.setup {
  layouts = {
    {
      elements = {
        {
          id = "console",
          size = 0.05,
        },
        {
          id = "breakpoints",
          size = 0.25,
        },
        {
          id = "stacks",
          size = 0.25,
        },
        {
          id = "watches",
          size = 0.20,
        },
        {
          id = "scopes",
          size = 0.25,
        },
      },
      position = "left",
      size = 30,
    },
    {
      elements = {
        {
          id = "repl",
          size = 1.0,
        },
      },
      position = "bottom",
      size = 30,
    },
  },
}

local dapgo = require 'dap-go'
-- loads .go_dap config file then reads a key from it to launch our debugger process
local function load_go_config(key --[[string]])
  local cwd = vim.fn.getcwd()
  local fp = cwd .. '/.go_dap.properties'

  -- see if the file exists
  function file_exists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
  end

  -- get all lines from a file, returns an empty
  -- list/table if the file does not exist
  function lines_from(file)
    if not file_exists(file) then return {} end
    local lines = {}
    for line in io.lines(file) do
      lines[#lines + 1] = line
      local args = vim.fn.split(line, "=", true)
      lines[args[1]] = args[2]
    end
    return lines
  end

  -- tests the functions above
  local lines = lines_from(fp)

  return lines[key]
end
dapgo.setup {
  dap_configurations = {
    -- shamelessly stolen from: https://github.com/leoluz/nvim-dap-go/issues/50#issuecomment-1559324365
    {
      type = "go",
      name = "Debug Package (Arguments)",
      request = "launch",
      program = "${fileDirname}",
      args = function()
        local args_string = vim.fn.input("Args(split by <space>): ")
        return vim.fn.split(args_string, " ", true)
      end,
    },
    -- allow env var lazy calls to allow rapid calls to run previous
    -- sample usage:
    -- export go_main=./cmd/prettier && export go_args=""
    {
      type = "go",
      name = "Debug Package (.go_dap.properties)",
      request = "launch",
      program = function ()
        return load_go_config("go_main")
      end,
      args = function()
        local go_args = load_go_config("go_args")
        return vim.fn.split(go_args, " ", true)
        -- return ""
      end,
    },
  },
}
