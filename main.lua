-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"]

mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

local dir = "."
local function req(path) return require(dir.."/"..path) end

-- Core
dir = "./core/utility"
req("Misc")
req("Proxy")

-- Tests
local dirs = path.get_directories(path.combine(PATH, "tests"))
for _, dir in ipairs(dirs) do
    require(path.combine(dir, "__init.lua"))
end