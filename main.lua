-- ReturnsAPI

PATH           = _ENV["!plugins_mod_folder_path"]
RAPI_NAMESPACE = "rapi" -- Namespace for ReturnsAPI that is used internally

mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

-- Helper
local function req(dir, file) return require("./core/"..dir.."/"..file) end
local function make() local _t = {} return setmetatable({}, {__index = function(t, k) return _t[k] end, __newindex = function(t, k, v) if _t[k] and table.merge then table.merge(_t[k], v) return end _t[k] = v end}) end

-- Global tables
G = {}          -- Globals
P = P or {}     -- Persistent globals that are not reinitialized on hotload
C = {}          -- Public classes for export
M = M or make() -- Metatables for classes <br><br>Setting an existing table will merge it instead of overwriting; <br>this allows ReturnsAPI hotloads to automatically update existing classes
W = W or make() -- Metatables for wrappers <br><br>Setting an existing table will merge it instead of overwriting; <br>this allows ReturnsAPI hotloads to automatically update existing wrappers

-- Core
local order = {
    "extensions",
    "utility",
    "data_structures",
}
for _, dir in ipairs(order) do
    local files = path.get_files(path.combine(PATH, "core", dir))
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
require("./tests/Tests.lua")
local dirs = path.get_directories(path.combine(PATH, "tests"))
for _, dir in ipairs(dirs) do
    require(path.combine(dir, "__init.lua"))
end

P.hotload = true