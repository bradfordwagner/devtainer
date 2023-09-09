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
    a = { fg = colors.green, bg = colors.dark_asphalt , gui = "bold", },
    c = { fg = colors.dark_cyan, bg = colors.dark_asphalt },
}

require 'lualine'.setup {
  options = {
    -- https://github.com/nvim-lualine/lualine.nvim/blob/master/THEMES.md
    -- theme = 'onedark'
    theme = challenger_deep
  },
  sections = {
    lualine_a = {
      {
        'filename',
        path = 1, -- 1: Relative path
      }
    },
  },
  inactive_sections = {
    lualine_a = {
      {
        'filename',
        path = 1, -- 1: Relative path
      }
    },
  },
}
