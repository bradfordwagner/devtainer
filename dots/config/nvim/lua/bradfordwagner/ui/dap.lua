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
    {
      type = "go",
      name = "Attach remote",
      mode = "remote",
      request = "attach",
    },
  },
}
