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
          id = "scopes",
          size = 0.25,
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
      name = "Debug Package (Env)",
      request = "launch",
      program = function ()
        return os.getenv("go_main")
      end,
      args = function()
        return vim.fn.split(os.getenv("go_args"), " ", true)
      end,
    },
  },
}
