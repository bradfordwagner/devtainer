-- setup files configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'

return quick_telescope.setup {
  name = 'dirs',
  picker_options = {
    { name = 'jumpdir', cmd = 'Easypick jumpdir<cr>' },
  }
}
