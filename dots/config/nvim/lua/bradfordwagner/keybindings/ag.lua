-- setup ag configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'

return quick_telescope.setup {
  name = 'ag',
  picker_options = {
    ["f1"] = function () print('a') end,
    ["f2"] = function () print('b') end,
    ["command"] = 'echo "hi friends"',
  }
}
