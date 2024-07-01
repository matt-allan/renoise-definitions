local lexer = require "lexer"
local dump = require "dump"

local Kind = lexer.TokenKind

local tests = {
  {"---@meta", {}},
  {"---@meta foo", {Kind.meta, "foo"}},
  {"---Hello", {Kind.comment, "Hello"}},
  {"error(\"Do not try to execute this file\")", {}},
  {"renoise = {}", {Kind.var, "renoise", Kind.var_value, "{}"}},
  {"renoise.Osc.Message = {}", {Kind.var, "renoise.Osc.Message", Kind.var_value, "{}"}},
  {"renoise.API_VERSION = 6.1", {Kind.var, "renoise.API_VERSION", Kind.var_value, "6.1"}},
  {"---@type number", {Kind.type, "number"}},
  {"---@return boolean", {Kind.returns, "boolean", Kind.returns_type, "boolean"}},
  {"---@return boolean enabled If the item is enabled", {
    Kind.returns, "boolean enabled If the item is enabled",
    Kind.returns_type, "boolean", Kind.returns_name, "enabled",
    Kind.returns_desc, "If the item is enabled"
  }},
  {"function renoise.app() end",{Kind.func, "renoise.app()"}},
  {"---@class Foo", {Kind.class, "Foo"}},
  {"---@type string[]", {Kind.type, "string[]", Kind.type_type, "string"}},
  {"---@type string|number", {Kind.type, "string|number", Kind.type_type, "string", Kind.type_type, "number"}},
  {"---@type string?", {Kind.type, "string?"}},
  {"---@deprecated do not use", {Kind.deprecated, "do not use"}},
}

for _,test in ipairs(tests) do
  local input, expected = unpack(test)
  local matches = lexer.lex(input)
  if #matches == 1 and type(matches[1]) == "number" and matches[1]-1 ~= #input then
      print("FAIL")
      print("Input:")
      print(input)
      print(string.format("Only matched %d of %d bytes", matches[1]-1, #input))
  end
  local ok = true
  for k,v in pairs(expected) do
    local actual = matches[k]
    if v ~= actual then
      ok = false
    end
  end
  if not ok then
      print("FAIL")
      print("Input:")
      print(input)
      print("Expected:")
      dump(expected)
      print("Actual:")
      dump(matches)
  end
end