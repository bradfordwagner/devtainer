-- util functions

local M = {}

-- extracts table into a list
function M.table_key(table)
  local keys = {}
  local n = 0
  for k,_ in pairs(table) do
    n = n + 1
    keys[n] = k
  end
  return keys
end

-- map
function M.table_map(table, k)
  local keys = {}
  local n = 0
  for _,v in pairs(table) do
    n = n + 1
    keys[n] = v[k]
  end
  return keys
end

function M.reduce(list, delim)
  local res = ''
  for k,v in pairs(list) do
    res = res .. v .. delim
  end
  return res
end

M.telescope_layout_config = {
  height = 0.66,
  width = 0.66,
}

local res = M.reduce({"a", "b"}, '\n')
print('res=' .. res)

return M
