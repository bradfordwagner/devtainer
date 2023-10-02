-- setup buffers configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'
local builtin = require 'telescope.builtin'

return quick_telescope.setup {
  name = 'buffers',
  picker_options = {
    { name = 'find', cmd = builtin.current_buffer_fuzzy_find },
    { name = 'list', cmd = builtin.buffers },
    { name = 'commit history', cmd = builtin.git_bcommits },
    {
      name = 'word',
      cmd = function ()
        local current_word = vim.call('expand', '<cword>')
        if current_word ~= nil then vim.cmd(string.format('BLines %s', current_word)) end
      end
    },
    {
      name = 'full word',
      cmd = function()
        local current_word = vim.call('expand', '<cWORD>')
        print(current_word)
        if current_word ~= nil then vim.cmd(string.format('BLines %s', current_word)) end
      end
    },
    -- from fzf.vim
    { name = 'tags', cmd = ':BTags' },
  }
}
