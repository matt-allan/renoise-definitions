local function eprint(...)
  for i=1,select("#", ...) do
    io.stderr:write(select(i, ...))
    io.stderr:write("\n")
  end
end

local function dump(value, depth, key)
  local linePrefix = ""
  local spaces = ""

  if key ~= nil then
    linePrefix = "[" .. key .. "] = "
  end

  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i = 1, depth do spaces = spaces .. "  " end
  end

  if type(value) == 'table' then
    local mTable = getmetatable(value)
    if mTable == nil then
      eprint(spaces .. linePrefix .. "(table) ")
    else
      eprint(spaces .. "(metatable) ")
      value = mTable
    end
    for tableKey, tableValue in pairs(value) do
      dump(tableValue, depth, tableKey)
    end
  elseif type(value) == 'function' or
      type(value) == 'thread' or
      type(value) == 'userdata' or
      value == nil
  then
    eprint(spaces .. tostring(value))
  else
    eprint(spaces .. linePrefix .. "(" .. type(value) .. ") " .. tostring(value))
  end
end

return dump