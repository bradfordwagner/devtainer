-- Enable colors in the terminal.
if vim.fn.has('termguicolors') then
    vim.cmd('set termguicolors')
end

require('colorizer').setup()
