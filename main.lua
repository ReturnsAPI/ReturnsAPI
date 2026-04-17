-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"]

mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

-- Helper
local function req(dir, file) return require("./core/"..dir.."/"..file) end
local function make() local _t = {} return setmetatable({}, {__index = function(t, k) return _t[k] end, __newindex = function(t, k, v) if _t[k] then table.merge(_t[k], v) return end _t[k] = v end}) end

-- Global tables
G = {}          -- Globals
P = P or {}     -- Persistent globals that are not reinitialized on hotload
C = {}          -- Public classes for export
M = M or make() -- Metatables for classes <br>Setting an existing table will merge it instead of overwriting; <br>this allows ReturnsAPI hotloads to automatically update existing wrappers
W = W or make() -- Metatables for wrappers <br>Setting an existing table will merge it instead of overwriting; <br>this allows ReturnsAPI hotloads to automatically update existing wrappers

-- Core
local dirs = {
    "extensions",
    "utility",
    "data_structures",
}
for _, dir in ipairs(dirs) do
    local files = path.get_files(path.combine(PATH, "core", dir))
    for _, file in ipairs(files) do
        require(file)
    end
end

-- Tests
require("./tests/Tests.lua")
local dirs = path.get_directories(path.combine(PATH, "tests"))
for _, dir in ipairs(dirs) do
    require(path.combine(dir, "__init.lua"))
end

P.hotload = true