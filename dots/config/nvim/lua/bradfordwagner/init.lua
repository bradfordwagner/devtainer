require("noice").setup()
require("notify").setup {
  render = "default",
  stages = "slide",
  fps = 60,
  top_down = true,
}

require("bufferline").setup {
  options = {
    mode = "tabs",
    separator_style = "thick",
    show_duplicate_prefix = false,
  }
}

require("nvim-tree").setup {
  view = {
    float = {
      enable = false,
    }
  }
}

local challenger_deep = require('lualine.themes.challenger_deep')
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
require('lualine').setup {
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

require('colorizer').setup()

require('nvim-treesitter.configs').setup {
  -- A list of parser names, or "all"
  ensure_installed = {
    "bash",
    "go",
    "gomod",
    "hcl",
    "javascript",
    "markdown",
    "python",
    "typescript",
    "yaml",
  },

  -- Install parsers synchronously (only applied to `ensure_installed`)
  sync_install = false,

  -- List of parsers to ignore installing (for "all")
  --ignore_install = {},

  highlight = {
    -- `false` will disable the whole extension
    enable = true,

    -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
    -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
    -- the name of the parser)
    -- list of language that will be disabled
    --disable = {"markdown"},

    -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
    -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
    -- Using this option may slow down your editor, and you may see some duplicate highlights.
    -- Instead of true it can also be a list of languages
    additional_vim_regex_highlighting = false,
  },
}
