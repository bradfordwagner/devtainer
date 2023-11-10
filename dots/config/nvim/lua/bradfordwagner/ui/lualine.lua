local challenger_deep = require 'lualine.themes.challenger_deep'
-- Change the background of lualine_c section for normal mode
-- challenger_deep.normal.c.bg = '#112233'
local colors = {
  red            = "#ff8080",
  green          = "#95ffa4",
  yellow         = "#ffe9aa",
  cyan           = "#aaffe4",
  white          = "#F3F3F3",
  dark_red       = "#ff5458",
  dark_green     = "#62d196",
  dark_yellow    = "#ffb378",
  dark_cyan      = "#63f2f1",
  dark_asphalt   = "#565575",
  asphalt_subtle = "#100E23",
}
-- override the inactive block, it wasn't visible enough
-- see base here for color scheme https://github.com/challenger-deep-theme/vim/blob/master/lua/lualine/themes/challenger_deep.lua
challenger_deep.inactive = {
    a = { fg = colors.green, bg = colors.asphalt_subtle , gui = "bold", },
    c = { fg = colors.dark_cyan, bg = colors.asphalt_subtle },
}
challenger_deep.normal = {
    a = { fg = colors.cyan, bg = colors.dark_asphalt , gui = "bold", },
    b = { fg = colors.white, bg = colors.dark_asphalt },
    c = { fg = colors.white, bg = colors.dark_asphalt },
}
require 'lualine'.setup {
  options = {
    -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
    theme = 'onedark'
    -- theme = challenger_deep
  },
  sections = {
    lualine_a = {
      { 'filename', path = 1 },
      -- paste mode from - https://github.com/nvim-lualine/lualine.nvim/issues/325
      { 'mode', fmt = function(mode) return vim.go.paste == true and mode .. ' (paste)' or mode end },
    },
  },
  inactive_sections = {
    lualine_a = {
      { 'filename', path = 1 },
    },
  },
}
