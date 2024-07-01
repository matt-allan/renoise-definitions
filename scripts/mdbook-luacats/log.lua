local LOG_LEVELS = {
  trace = 1,
  debug = 2,
  info = 3,
  warn = 4,
  error = 5
}

local log_env = LOG_LEVELS[os.getenv("LUA_LOG") or "info"] or LOG_LEVELS["info"]

local log = {}

for name, value in pairs(LOG_LEVELS) do
  log[name] = function(msg, ...)
    if log_env > value then return end
    local line = string.format("[%s] ", string.upper(name))
    if select("#") then
      line = line .. string.format(msg, ...)
    else
      line = line .. msg
    end
    io.stderr:write(line .. "\n")
  end
end

return log