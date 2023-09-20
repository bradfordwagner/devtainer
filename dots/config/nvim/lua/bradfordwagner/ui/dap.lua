local dapui = require("dapui")
dapui.setup {}

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
