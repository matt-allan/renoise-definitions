local lexer = require "lexer"
local TokenKind = lexer.TokenKind

---@class Node
---@field kind TokenKind
---@field name string
---@field desc string?
---@field type string?
---@field subtypes string[]
---@field value string?
---@field deprecated boolean?
---@field scope string?
---@field comments string[]
---@field extends string[]
---@field fields Node[]
---@field params Node[]
---@field returns Node[]
local Node = {}

---@return Node
function Node:new(kind, name)
  return {
    kind = kind,
    name = name,
    subtypes = {},
    comments = {},
    extends = {},
    fields = {},
    params = {},
    returns = {},
  }
end

---@class Parser
---@field private tokens string[]
---@field private len integer
---@field private pos integer
---@field current_node Node The WIP node with no ID yet
---@field last_node Node The last parsed node in case we have trailing children
local Parser = {}
Parser.__index = Parser

---Create a new parser.
---@return Parser
function Parser:new()
  return setmetatable({
    tokens = {},
    len = 1,
    pos = 1,
  }, Parser)
end

---@param tokens string[]
function Parser:parse(tokens)
  self.tokens = tokens
  self.len = #tokens
  self.pos = 1
  self.current_node = Node:new("", "")
  self.last_node = nil

  local nodes = {}

  while not self:done() do
    local token = self:peek()

    local method = self[token]

    if not method then
      error(string.format("Missing parse method for '%s'", token))
    end

    local finished = method(self)

    if finished then
      table.insert(nodes, self.current_node)
      self.last_node = self.current_node
      self.current_node = Node:new("", "")
    end
  end

  return nodes
end

---@return TokenKind
function Parser:peek()
  return self.tokens[self.pos]
end

---@param expected_token TokenKind
---@return string
function Parser:consume(expected_token)
  local token, value = self.tokens[self.pos], self.tokens[self.pos+1]

  if expected_token ~= token then
    error(string.format("expected token %s, got %s", expected_token, token))
  end

  self.pos = self.pos + 2

  return value
end

---@return boolean
function Parser:done()
  return self.pos > #self.tokens
end

-- TODO: implement remaining methods

-- function Parser:alias()
-- end

-- function Parser:class()
-- end

function Parser:comment()
  table.insert(self.current_node.comments, self:consume(TokenKind.comment))
end

-- function Parser:deprecated()
-- end

-- function Parser:enum()
-- end

-- function Parser:field()
-- end

function Parser:func()
  self.current_node.name = self:consume(TokenKind.func)
  self.current_node.kind = TokenKind.func

  return true
end

-- function Parser:meta()
-- end

function Parser:param()
  local name = self:consume(TokenKind.param)

  local param = Node:new(TokenKind.param, name)

  param.type = self:consume(TokenKind.param_type)

  if self:peek() == TokenKind.param_desc then
    param.desc = self:consume(TokenKind.param_desc)
  end

  table.insert(self.current_node.params, param)
end

function Parser:returns()
  self:consume(TokenKind.returns)

  local returns = Node:new(TokenKind.returns, "")

  returns.type = self:consume(TokenKind.returns_type)

  if self:peek() == TokenKind.returns_name then
    returns.name = self:consume(TokenKind.returns_name)
  end

  if self:peek() == TokenKind.returns_desc then
    returns.desc = self:consume(TokenKind.returns_desc)
  end

  table.insert(self.current_node.returns, returns)
end

function Parser:type()
  self.current_node.type = self:consume(TokenKind.type)
end

function Parser:var()
  self.current_node.name = self:consume(TokenKind.var)
  self.current_node.kind = TokenKind.var
  self.current_node.value = self:consume(TokenKind.var_value)

  return true
end

return Parser