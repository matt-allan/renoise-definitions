local lex = require "lex"
local dump = require "dump"

local tests = {
  {"---@meta", {}},
  {"---@meta foo", {"meta_name", "foo"}},
  {"---Hello", {"comment", "Hello"}},
  {"error(\"Do not try to execute this file\")", {}},
  {"renoise = {}", {"var", "renoise", "value", "{}"}},
  {"renoise.Osc.Message = {}", {"var", "renoise.Osc.Message", "value", "{}"}},
  {"renoise.API_VERSION = 6.1", {"var", "renoise.API_VERSION", "value", "6.1"}},
  {"---@type number", {"doc_type", "number"}},
  {"---@return boolean", {"return_type", "boolean"}},
  {"---@return boolean enabled If the item is enabled", {
    "return_type", "boolean", "return_name", "enabled",
    "return_desc", "If the item is enabled"
  }},
  {"function renoise.app() end",{"func", "renoise.app()"}},
  {"---@class Foo", {"class_name", "Foo"}},
  {"---@type string[]", {"doc_type", "string[]", "subtype", "string"}},
  {"---@type string|number", {"doc_type", "string|number", "subtype", "string", "subtype", "number"}},
  {"---@type string?", {"doc_type", "string?"}},
}

for _,test in ipairs(tests) do
  local input, expected = unpack(test)
  local matches = {lex(input)}
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