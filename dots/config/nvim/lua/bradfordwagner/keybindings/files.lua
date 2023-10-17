-- setup files configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'
local builtin = require 'telescope.builtin'

-- find files
local ff = function(opts)
  return function()
    builtin.find_files(opts)
  end
end

return quick_telescope.setup {
  name = 'files',
  picker_options = {
    { name = 'project files', cmd = ff({}) },
    { name = 'project files - no ignore', cmd = ff({no_ignore = true}) },
    { name = 'project files - hidden', cmd = ff({hidden = true}) },
    { name = 'project files - no ignore, hidden', cmd = ff({no_ignore = true, hidden = true}) },
    { name = 'git', cmd = builtin.git_files },
    { name = 'history', cmd = builtin.oldfiles },
  }
}
