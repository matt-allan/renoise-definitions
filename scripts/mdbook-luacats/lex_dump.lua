local lex = require "lex"
local dump = require "dump"

local input = io.read("*all")

dump({ lex(input) })