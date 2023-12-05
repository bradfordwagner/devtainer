-- https://github.com/echasnovski/mini.nvim
-- https://github.com/echasnovski/mini.nvim/blob/main/readmes/mini-animate.md
local animate = require('mini.animate')
local timing = animate.gen_timing.linear({duration = 150, unit = 'total'})
animate.setup({
    cursor = {
      timing = timing,
    },
    scroll = {
      timing = timing,
    },
    resize = {
      timing = timing,
    },
    open = {
      timing = timing,
    },
    close = {
      timing = timing,
    },
})
