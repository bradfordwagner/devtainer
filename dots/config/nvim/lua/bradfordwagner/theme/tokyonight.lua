--- https://github.com/folke/tokyonight.nvim
local colors = require("tokyonight").setup({
    styles = {
    -- Style to be applied to different syntax groups
    -- Value is any valid attr-list value for `:help nvim_set_hl`
    comments = { italic = false },
    keywords = { italic = false },
  },
})
