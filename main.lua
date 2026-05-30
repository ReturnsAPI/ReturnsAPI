-- ReturnsAPI

__DEACTIVATE_OLD = true -- DEBUG

PATH                = _ENV["!plugins_mod_folder_path"]
RAPI_NAMESPACE      = "rapi"        -- Namespace for ReturnsAPI that is used internally
PERMANENT_NAMESPACE = "__permanent" -- Namespace for ReturnsAPI for internal callbacks that persist on hotload

mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

-- Global tables
local function make() local _t = {} return setmetatable({}, {__index = function(t, k) return _t[k] end, __newindex = function(t, k, v) if _t[k] and table.merge then table.merge(_t[k], v) return end _t[k] = v end}) end

G = {}          -- Globals
P = P or {}     -- Persistent globals that are not reinitialized on hotload
C = {}          ---@type table<string, table> Public classes for export
M = M or make() ---@type table<string, table> Metatables for classes <br><br>Setting an existing table will merge it instead of overwriting; <br>this allows RAPI hotloads to automatically update existing classes
W = W or make() ---@type table<string, table> Metatables for wrappers <br><br>Setting an existing table will merge it instead of overwriting; <br>this allows RAPI hotloads to automatically update existing wrappers

-- Run import functions for RAPI itself
-- This needs to be called before loading core
if P.run_on_import then
    for _, fn in ipairs(P.run_on_import) do
        fn(RAPI_NAMESPACE)
    end
end

-- core/
local dirs = path.get_directories(path.combine(PATH, "core"))
for _, dir in ipairs(dirs) do
    local files = path.get_files(dir)
    for _, file in ipairs(files) do
        require(file)
    end
end

-- run_after_core
if G.run_after_core then
    for _, fn in ipairs(G.run_after_core) do
        fn()
    end
end

-- ENVY exports
require("./envy")

-- tests/
if path.exists(path.combine(PATH, "tests")) then
    require("./tests/Tests.lua")
end

P.hotload = true