-- setup ag configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'

return quick_telescope.setup {
  name = 'find',
  picker_options = {
    { name = 'live', cmd = 'Ag<cr>' },
    {
      name = 'input',
      cmd = function()
        vim.ui.input({ prompt = 'Ag> ' }, function (input)
          if input ~= nil then vim.cmd(string.format('Ag %s', input)) end
        end)
      end },
    {
      name = 'word',
      cmd = function()
        local current_word = vim.call('expand', '<cword>')
        if current_word ~= nil then vim.cmd(string.format('Ag %s', current_word)) end
      end
    },
    {
      name = 'full word',
      cmd = function()
        local current_word = vim.call('expand', '<cWORD>')
        print(current_word)
        if current_word ~= nil then vim.cmd(string.format('Ag %s', current_word)) end
      end
    },
  }
}
