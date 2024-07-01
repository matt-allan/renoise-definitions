local filepath = {}
local PATH_SEP = package.config:sub(1,1)
local PATH_SEP_BYTE = string.byte(PATH_SEP)

---@param p string
---@param ... string
---@return string
function filepath.join(p, ...)
  for _,s in ipairs({...}) do
    if string.byte(p, -1) ~= PATH_SEP_BYTE then
      p = p .. PATH_SEP
    end
    p = p .. s
  end

  return p
end
---@param p string
---@return boolean
function filepath.is_absolute(p)
  return string.sub(p, 1, 1) == PATH_SEP
end

---Split a string on the last occurence of the given character code.
---@param s string
---@param c integer
---@return string, string
local function rsplit(s, c)
  local len = #s
  for i = len,1, -1 do
    if string.byte(s, i) == c then
      return string.sub(s, 1, i-1), string.sub(s, i+1)
    end
  end

  return s, ""
end

function filepath.split(p)
  return rsplit(p, PATH_SEP_BYTE)
end

function filepath.dirname(p)
  local dirname, _ = rsplit(p, PATH_SEP_BYTE)

  return dirname
end

function filepath.basename(p, suffix)
  local _, basename = rsplit(p, PATH_SEP_BYTE)

  if suffix and string.sub(basename, -#suffix) == suffix then
    return string.sub(basename, 1, -#suffix -1)
  end

  return basename
end

return filepath