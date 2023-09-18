-- setup ag configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'


local function open_changelist()
  vim.cmd('copen')
  vim.cmd('horizontal resize 25%')
end

local function prompt(callback)
  return function()
    vim.ui.input({ prompt = 'vim_grep> ' }, function (input)
      if input ~= nil then
        callback(input)
      end
    end)
  end
end

return quick_telescope.setup {
  name = 'vimgrep',
  picker_options = {
-- " vimgrep helpers
-- " current file
-- map <expr><silent> <Space>ggi ":vimgrep /" . input("grep current file: ") . "/ % \<CR>co"
-- map <silent> <Space>ggww :vimgrep /<c-r><c-w>/ % <cr>co
-- map <silent> <Space>ggwe :vimgrep /<c-r><c-a>/ % <cr>co
-- " all files
-- map <expr><silent> <Space>gai ":vimgrep /" . input("grep all files: ") . "/ **/* \<CR>co"
-- map <silent> <Space>gaww :vimgrep /<c-r><c-w>/ **/* <cr>co
-- map <silent> <Space>gawe :vimgrep /<c-r><c-a>/ **/* <cr>co
-- " dir matching
-- map <expr><silent> <Space>gd ":vimgrep /" . input("grep files in directory: ") . "/ **/**" . input("dir match: ") . "**/* \<CR>co"
    { 
      name = 'current file',
      cmd = prompt(function (input)
        vim.cmd(string.format('vimgrep /%s/ %s', input, '%'))
        open_changelist()
      end)
    },
    { 
      name = 'current file word',
      cmd = function ()
        local current_word = vim.call('expand', '<cword>')
        vim.cmd(string.format('vimgrep /%s/ %s', current_word, '%'))
        open_changelist()
      end
    },
    -- { 
    --   name = 'input',
    --   cmd = function()
    --     vim.ui.input({ prompt = 'Ag> ' }, function (input)
    --       if input ~= nil then vim.cmd(string.format('Ag %s', input)) end
    --     end)
    --   end },
    -- { 
    --   name = 'word',
    --   cmd = function()
    --     local current_word = vim.call('expand', '<cword>')
    --     if current_word ~= nil then vim.cmd(string.format('Ag %s', current_word)) end
    --   end 
    -- },
    -- { 
    --   name = 'full word',
    --   cmd = function()
    --     local current_word = vim.call('expand', '<cWORD>')
    --     print(current_word)
    --     if current_word ~= nil then vim.cmd(string.format('Ag %s', current_word)) end
    --   end 
    -- },
  }
}
