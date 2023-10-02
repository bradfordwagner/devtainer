-- https://github.com/ray-x/go.nvim
local go = require 'go'
go.setup {
  -- use remote single server to save on resources
  gopls_cmd = { 'gopls', '-remote', "unix;/tmp/gopls-daemon-socket" },
}
