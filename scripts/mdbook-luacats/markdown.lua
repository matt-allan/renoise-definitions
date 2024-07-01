local strings = require "strings"

local markdown = {}

-- TODO: add other root node types
local views = {
  var = function (sb, node)
    sb:add(string.format("# `%s`\n", node.name))

    sb:add("```lua\n")
    sb:add(string.format("%s = %s\n", node.name, node.value))
    sb:add("```\n")

    for _, comment in ipairs(node.comments) do
      sb:add(comment)
      sb:add("\n")
    end
  end,
}

---@param nodes Node[]
---@return string
function markdown.render(nodes)
  local sb = strings.Builder:new()

  for _,node in ipairs(nodes) do
    local view = views[node.kind]
    if view then
      view(sb, node)
    end
  end

  return sb:string()
end

return markdown