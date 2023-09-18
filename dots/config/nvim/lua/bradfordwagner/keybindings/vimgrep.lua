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
    { 
      name = 'file input',
      cmd = prompt(function (input)
        vim.cmd(string.format('vimgrep /%s/ %s', input, '%'))
        open_changelist()
      end)
    },
    { 
      name = 'file word',
      cmd = function ()
        local current_word = vim.call('expand', '<cword>')
        vim.cmd(string.format('vimgrep /%s/ %s', current_word, '%'))
        open_changelist()
      end
    },
    { 
      name = 'file full word',
      cmd = function ()
        local current_word = vim.call('expand', '<cWORD>')
        vim.cmd(string.format('vimgrep /%s/ %s', current_word, '%'))
        open_changelist()
      end
    },
    { 
      name = 'all input',
      cmd = prompt(function (input)
        vim.cmd(string.format('vimgrep /%s/ %s **/*', input, '%'))
        open_changelist()
      end)
    },
    { 
      name = 'all word',
      cmd = function ()
        local current_word = vim.call('expand', '<cword>')
        vim.cmd(string.format('vimgrep /%s/ %s **/*', current_word, '%'))
        open_changelist()
      end
    },
    { 
      name = 'all full word',
      cmd = function ()
        local current_word = vim.call('expand', '<cWORD>')
        vim.cmd(string.format('vimgrep /%s/ %s **/*', current_word, '%'))
        open_changelist()
      end
    },
    -- TODO
    -- map <expr><silent> <Space>gd ":vimgrep /" . input("grep files in directory: ") . "/ **/**" . input("dir match: ") . "**/* \<CR>co"
    -- { 
    --   name = 'all dir',
    --   cmd = prompt(function (search)
    --     prompt(function (directory)
    --       vim.cmd(string.format('vimgrep /%s/ %s **/*%s**/*', search, '%', directory))
    --       open_changelist()
    --     end)
    --   end)
    -- },
  }
}
