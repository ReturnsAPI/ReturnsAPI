-- ReturnsAPI

PATH           = _ENV["!plugins_mod_folder_path"]
RAPI_NAMESPACE = "rapi" -- Namespace for ReturnsAPI that is used internally

mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

-- Global tables
local function make() local _t = {} return setmetatable({}, {__index = function(t, k) return _t[k] end, __newindex = function(t, k, v) if _t[k] and table.merge then table.merge(_t[k], v) return end _t[k] = v end}) end

G = {}          -- Globals
P = P or {}     -- Persistent globals that are not reinitialized on hotload
C = {}          -- Public classes for export
M = M or make() -- Metatables for classes <br><br>Setting an existing table will merge it instead of overwriting; <br>this allows RAPI hotloads to automatically update existing classes
W = W or make() -- Metatables for wrappers <br><br>Setting an existing table will merge it instead of overwriting; <br>this allows RAPI hotloads to automatically update existing wrappers

-- Core
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

-- Tests
local tests_dir = path.combine(PATH, "tests")
if path.exists(tests_dir) then
    require("./tests/Tests.lua")
    local dirs = path.get_directories(tests_dir)
    for _, dir in ipairs(dirs) do
        require(path.combine(dir, "__init.lua"))
    end
end

P.hotload = true