local strings = {}

---Efficient incremental string building.
---Based on the design described in Programming in Lua ch. 11.6 - String Buffers.
---https://www.lua.org/pil/11.6.html
---@class StringBuilder
---@field private stack string[]
local Builder = {}
strings.Builder = Builder

---Create a new builder.
---@return StringBuilder
function Builder:new()
  self.__index = self

  return setmetatable({
    stack = {},
  }, Builder)
end

---Push a string onto the builder's stack.
---@param ... string
function Builder:add(...)
  for _,s in ipairs({...}) do
    table.insert(self.stack, s)

    for i=#self.stack - 1, 1, -1 do
      if string.len(self.stack[i]) > string.len(self.stack[i+1]) then
        break
      end
      self.stack[i] = self.stack[i] .. table.remove(self.stack)
    end
  end
end

function Builder:string()
  return table.concat(self.stack)
end

---Build the string.
---@return string
function Builder:__tostring()
  return self:string()
end

return strings