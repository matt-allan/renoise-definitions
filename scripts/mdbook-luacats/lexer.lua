local lpeg = require "lpeg";

local locale = lpeg.locale();

local P, S, V = lpeg.P, lpeg.S, lpeg.V;

local C, Cb, Cc, Cg, Cs, Cp, Cmt, Ct =
    lpeg.C, lpeg.Cb, lpeg.Cc, lpeg.Cg, lpeg.Cs, lpeg.Cp, lpeg.Cmt, lpeg.Ct;

local lexer = {}

---@enum TokenKind
lexer.TokenKind = {
  alias = "alias",
  alias_type = "alias_type",
  class = "class",
  class_extends = "class_extends",
  comment = "comment",
  deprecated = "deprecated",
  enum = "enum",
  field = "field",
  field_scope = "field_scope",
  field_type = "field_type",
  field_desc = "field_desc",
  func = "func",
  meta = "meta",
  param = "param",
  param_type = "param_type",
  param_desc = "param_desc",
  returns = "returns",
  returns_type = "returns_type",
  returns_name = "returns_name",
  returns_desc = "returns_desc",
  type = "type",
  type_desc = "type_desc",
  var = "var",
  var_value = "var_value",
}
local Kind = lexer.TokenKind

local function any_delims(open, close)
  return P(open) * (P(1) - P(close))^0 * P(close)
end

--
-- Common
--
-- All whitespace
local space = locale.space ^ 0
-- 1 or more space characters
local spaces = P " "^1
-- Anything until the end of line
local until_eol = (P(1) - P "\n")^1
-- A Lua identifier
local ident = (locale.alpha + P "_") * (locale.alnum + P "_") ^ 0
-- A Lua identifier with a namespace such as a table or module (`foo.bar.baz`)
local ns_ident = ident * (P "." * ident)^0
local any_parens = any_delims("(", ")")
local any_braces = any_delims("{", "}")
local any_brackets = any_delims("<", ">")
--
-- Annotations
--
-- A visibility qualifier
local scope = P "private" + P "protected" + P "public" + P "package"
-- A type specifier in docs
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
  array = V "single" * P "[]",
  line_comment = P "#" * spaces * until_eol,
  union = V "single" * space
    * (P "|" * space * V "single" * space)^1,
  multiline_union = P "---|" * spaces
    * V "single" * space * V "line_comment" * space
    * (
      P "---|" * space
      * V "single" * space * V "line_comment" * space
    ) ^ 1
}
-- `@meta [name]`
local at_meta = P "---@meta" * (spaces * Cc(Kind.meta) * C(ident))^0
-- `@type foo`
local at_type = P "---@type" * spaces * Cc(Kind.type) * C(doc_type)
-- `@class Foo[: Bar]`
local at_class = P "---@class" * spaces
  * Cc(Kind.class) * C(ns_ident)
  * (spaces * P ":" * Cc(Kind.class_extends) * C(ns_ident))^0
-- `@enum Foo`
local at_enum = P "---@enum" * spaces
  * Cc(Kind.enum) * C(ns_ident)
--- `@deprecated for some reason` 
local at_deprecated = P "---@deprecated"
  * (spaces * Cc(Kind.deprecated) * C(until_eol))^0
-- `@field [private] foo integer`
local at_field = P "---@field" * spaces
  * (Cc(Kind.field_scope) * C(scope) * spaces)^0
  * Cc(Kind.field) * C(ident) * spaces
  * Cc(Kind.field_type) * C(doc_type)
  * (spaces * Cc(Kind.field_desc) * C(until_eol))^0
-- `@param foo number`
local at_param = P "---@param" * spaces
  * Cc(Kind.param) * C(ident) * spaces
  * Cc(Kind.param_type) * C(doc_type)
  * (spaces * Cc(Kind.param_desc) * C(until_eol))^0
-- `@alias foo number`
local at_alias = P "---@alias" * spaces
  * Cc(Kind.alias) * C(ident) * space
  * Cc(Kind.alias_type) * C(doc_type)
-- `@return string foo Some description`
local at_return = P "---@return" * spaces
  * Cc(Kind.returns) * C(Cc(Kind.returns_type) * C(until_eol) -- todo: use doc_type here to capture sub types
  * (
    spaces * Cc(Kind.returns_name) * C(ident)
    * (spaces * Cc(Kind.returns_desc) * C(until_eol))^0
  )^0)
-- `--- A doc comment` 
local doc_comment = P "---" * Cc(Kind.comment) * C((P(1) - P "\n") ^ 0)
-- `-- A regular comment`  (ignored)
local comment = P "--" * (P(1) - P "\n") ^ 0
local doc = at_meta
  + at_type
  + at_class
  + at_deprecated
  + at_enum
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
local assign = Cc(Kind.var) * C(ns_ident) * space
  * P "=" * space
  * Cc(Kind.var_value)
  * (C(any_braces) + C(until_eol))
-- `function foo.bar:baz(a,b,c) end`
local func_declaration = Cc(Kind.func) * P "function" * space
    * C(
      ns_ident^1
      * (P ":" * ident)^-1
      * any_parens)
      * space * P "end"
local statement = func_call
    + func_declaration
    + assign
--
-- Full grammar
--
local cats_doc = (
    space
    * (doc + statement)
    * space
    * (space * P ";")^-1
  ) ^ 0

function lexer.lex(input)
  return {cats_doc:match(input)}
end

return lexer