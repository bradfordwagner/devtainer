require "nvim-tree".setup {
  view = {
    float = {
      enable = false,
    }
  },
  -- do not allow nvim tree to open by default when a directory is opened
  -- this especially affects jumpdir
  hijack_directories = {
    enable = false,
    auto_open = true,
  },
}
