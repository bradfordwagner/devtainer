-- setup ag configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'

return quick_telescope.setup {
  name = 'ag',
  picker_options = {
    ['live search'] = 'Ag<cr>',
    ['input'] = function() 
      vim.ui.input({ prompt = 'Ag> ' }, function (input)
        if input ~= nil then vim.cmd(string.format('Ag %s', input)) end
      end)
    end,
  }
}
