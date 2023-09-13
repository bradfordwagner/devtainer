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

local telescope = require 'telescope.builtin'
function M.find_files()
  telescope.find_files {
  }
  telescope.find_files {
  }
end

return M
