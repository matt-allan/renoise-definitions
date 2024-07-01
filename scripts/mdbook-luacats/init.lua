-- Allow running from the repo root (for mdbook)
package.path = 'scripts/mdbook-luacats/?.lua;?.lua;' .. package.path

local json = require ("dkjson").use_lpeg()
local lfs = require "lfs"
local log = require "log"
local filepath = require "filepath"
local lexer = require "lexer"
local Parser = require "parser"
local dump = require "dump"
local markdown = require "markdown"

local parser = Parser:new()

local function render_page(path)
  local file = io.open(path, "r")
  if not file then
    error(string.format("failed to open %s", path))
  end
  local input = file:read("*all")
  local tokens = lexer.lex(input)
  local nodes = parser:parse(tokens)
  --dump(nodes)
  local md = markdown.render(nodes)

  return md
end

local function build_chapters(path, parent)
  local chapters = {}
  for entry in lfs.dir(path) do
    if entry ~= "." and entry ~= ".." then
      local subpath = filepath.join(path, entry)
      if string.sub(entry, -4) == ".lua" then
        log.trace("file: %s", subpath)

        local chapter = {
          name = string.sub(entry, 1, -5),
          content = render_page(subpath),
          path = entry, -- TODO: resolve relative to root
          sub_items = {},
          parent_names = {},
        };

        if parent then
          for name in parent.parent_names do
            table.insert(chapter.parent_names, name)
          end
          table.insert(chapter.parent_names, parent.name)
        end

        table.insert(chapters, {
          Chapter = chapter
        })
      else
        log.trace("dir: %s", entry)
        -- TODO: find closest parent, then walk subdir
      end
    end
  end

  return chapters
end

local function main()
  if arg[1] == "supports" then
    os.exit(0)
  end

  local input = io.read("*all")

  local data, _pos, err = json.decode(input)

  if err then
    log.error("json.decode: %s", err)
    os.exit(1)
  end

  local ctx, book = unpack(data)

  log.info("Building book '%s'", ctx["config"]["book"]["title"])

  local root = ctx["root"]
  local config = ctx["config"]["preprocessor"]["luacats"]
  local definitions_path = config["definitions-path"]
  if not filepath.is_absolute(definitions_path) then
    definitions_path = filepath.join(root, definitions_path)
  end
  log.debug("Using definitions path %s", definitions_path)

  book["__non_exhaustive"] = json.null

  table.insert(book["sections"], {
    PartTitle = "API Reference",
  })

  local chapters = build_chapters(definitions_path)
  for _,chapter in ipairs(chapters) do
    table.insert(book["sections"], chapter)
  end

  io.stdout:write(json.encode(book))
end

main()