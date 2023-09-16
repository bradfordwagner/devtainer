-- setup files configuration

-- imports
local quick_telescope = require 'bradfordwagner.keybindings.quick_telescope'

return quick_telescope.setup {
  name = 'dirs',
  picker_options = {
    { name = 'jump', cmd = 'Easypick jumpdir' },
    { name = 'fd', cmd = 'Easypick finddir' },
    { name = 'root', cmd = 'Rooter' },
    { name = 'pwd', cmd = 'pwd' },
    {
      name = 'current file',
      cmd = function ()
        vim.cmd('cd %:p:h')
        vim.cmd('pwd')
      end
    },
    {
      name = 'reset',
      cmd = function ()
        local output = vim.fn.getenv('PWD') -- get original dir
        vim.cmd.cd(output) -- cd dir to pwd
        print(string.format('reset - %s', output))
      end
     },
    { name = 'workspace', cmd = 'Easypick workspace_find_dir' },
  }
}
