local lpeg = require "lpeg";
local dump = require "dump";

local locale = lpeg.locale();

local P, S, V = lpeg.P, lpeg.S, lpeg.V;

local C, Cb, Cc, Cg, Cs, Cp, Cmt, Ct =
    lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Cp, lpeg.Cmt, lpeg.Ct;

local function any_delims(open, close)
  return P(open) * (P(1) - P(close))^0 * P(close)
end

--
-- Common
--
-- All whitespace
local space = locale.space ^ 0
--- 1 or more space characters
local spaces = P " "^1
--- Anything until the end of line
local until_eol = (P(1) - P "\n")^1
--- A Lua identifier
local ident = (locale.alpha + P "_") * (locale.alnum + P "_") ^ 0
--- A Lua identifier with a namespace such as a table or module (`foo.bar.baz`)
local ns_ident = ident * (P "." * ident)^0
local any_parens = any_delims("(", ")")
local any_braces = any_delims("{", "}")
local any_brackets = any_delims("<", ">")
--
-- Annotations
--
--- A visibility qualifier
local visibility = P "private" + P "protected" + P "public" + P "package"
--- A type specifier in docs
local doc_type = P {
  "any",
  any = V "multiline_union" + V "union" + V "array" + V "optional" + V "basic",
  basic = ns_ident
    + any_delims("\"", "\'")
    + any_delims("'", "'")
    + (P "fun" * any_parens * (spaces * P ":" * spaces * V "basic")^0)
    + any_braces
    + (ident * any_brackets),
  optional = V "basic" * P "?",
  single = V "basic" + V "optional",
  array = Cc "subtype" * C(V "single") * P "[]",
  line_comment = P "#" * spaces * Cc("type_description") * C(until_eol),
  union = Cc "subtype" * C(V "single") * space
    * (P "|" * space * Cc("subtype") * C(V "single") * space)^1,
  multiline_union = P "---|" * spaces
    * Cc("subtype") * C(V "single") * space * V "line_comment" * space
    * (
      P "---|" * space
      * Cc("subtype") * C(V "single") * space * V "line_comment" * space
    ) ^ 1
}
-- `@meta [name]`
local at_meta = P "---@meta" * (spaces * Cc "meta_name" * C(ident))^0
--- `@type foo`
local at_type = P "---@type" * spaces * Cc "doc_type" * C(doc_type)
-- `@class Foo[: Bar]`
local at_class = P "---@class" * spaces
  * Cc "class_name" * C(ns_ident)
  * (spaces * P ":" * Cc "class_extends" * C(ns_ident))^0
--- `@field [visibility] foo integer`
local at_field = P "---@field" * spaces
  * (Cc "visibility" * C(visibility) * spaces)^0
  * Cc "field_name" * C(ident) * spaces
  * Cc "field_type" * C(doc_type)
  * (spaces * Cc "field_desc" * C(until_eol))^0
--- `@param foo Whatever`
local at_param = P "---@param" * spaces
  * Cc "param_name" * C(doc_type) * spaces
  * Cc "param_type" * C(doc_type)
  * (spaces * Cc "param_desc" * C(until_eol))^0
local at_alias = P "---@alias" * spaces
  * Cc "alias_name" * C(ident) * space
  * Cc "alias_type" * C(doc_type)
--- `@return string foo Some description`
local at_return = P "---@return" * spaces
  * Cc "return_type" * C(doc_type)
  * (
    spaces * Cc "return_name" * C(ident)
    * (spaces * Cc "return_desc" * C(until_eol))^0
  )^0
-- Plain `---  comments
local doc_comment = P "---" * Cc "comment" * C((P(1) - P "\n") ^ 0)
-- Plain `--  comments
local comment = P "--" * (P(1) - P "\n") ^ 0
local doc = at_meta
  + at_type
  + at_class
  + at_alias
  + at_param
  + at_field
  + at_return
  + doc_comment
  + comment
--
-- Lua statements
--
-- `foo(a,b)`
local func_call = ident * any_parens
-- `foo = {}`
local assign = Cc "var" * C(ns_ident) * space
  * P "=" * space
  * Cc "value"
  * (C(any_braces) + C(until_eol))
-- `function foo.bar:baz(a,b,c) end`
local func_declaration = Cc "func" * P "function" * space
    * C(
      ns_ident^1
      * (P ":" * ident)^-1
      * any_parens)
      * space * P "end"
local statement = func_call
    + func_declaration
    + assign

local cats_doc = (
    space
    * (doc + statement)
    * space
    * (space * P ";")^-1
  ) ^ 0

local function lex(input)
  return cats_doc:match(input)
end

return lex