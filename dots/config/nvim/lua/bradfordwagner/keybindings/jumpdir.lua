local M = {}

-- setup easy pick
local easypick = require 'easypick'
easypick.setup {
  pickers = {
    {
      name = "jd",
      command = "zsh -lc jdl",
      previewer = easypick.previewers.default(),
    },
  }
}

function M.find_files()
  vim.cmd [[
    Easypick jd
  ]]
  vim.cmd [[
    Rooter
  ]]
end

return M
