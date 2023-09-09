-- For key mappings for all modes.
local all_modes = { 'n', 'i', 'v', 't' }
local exclude_t = { 'n', 'i', 'v' }
local exclude_i  = { 'n', 'v', 't' }
local n_v = { 'n', 'v' }
local n_t = { 'n', 't' }
local n = 'n'

-- Function to map keys.
local map_key = vim.keymap.set
-- Default config for the keymaps.
local default_settings = {
    noremap = true,
    silent = true,
}

-- goyo keymaps
map_key(n, '<Space>zz', '<cmd>Goyo<cr>', default_settings)
map_key(n, '<Space>zx', '<cmd>Goyo!<CR><cmd>! tmux resize-pane -Z<CR>', default_settings)
