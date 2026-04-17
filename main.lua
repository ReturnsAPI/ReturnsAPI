-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"]

mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

local function req(dir, file) return require("./core/"..dir.."/"..file) end

-- Global tables
G = {}      -- Globals
P = P or {} -- Persistent globals that are not reinitialized on hotload
C = {}      -- Public classes for export

req("extensions",   "Table")
req("utility",      "Misc")

M = M or make_table_once()  -- Metatables for classes
W = W or make_table_once()  -- Metatables for wrappers

-- Core
req("extensions",   "Math")

req("utility",      "Proxy")
req("utility",      "ReadOnly")

-- Tests
require("./tests/Tests.lua")
local dirs = path.get_directories(path.combine(PATH, "tests"))
for _, dir in ipairs(dirs) do
    require(path.combine(dir, "__init.lua"))
end

P.hotload = true