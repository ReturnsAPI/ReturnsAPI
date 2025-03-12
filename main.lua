-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"

gmf = require("ReturnOfModding-GLOBAL/gmf")


-- ENVY initial setup
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]


-- Load core
_CLASS = {}     -- All public classes should self-populate these two tables
_CLASS_MT = {}  -- The metatable to set for the class (if applicable) when copying in envy.lua

local dirs = path.get_directories(PATH.."core")
for _, dir in ipairs(dirs) do
    if path.filename(dir) ~= "data" then
        local files = path.get_files(dir)
        for _, file in ipairs(files) do
            require(file)
        end
    end
end


-- Create __ref_list
__ref_list = List.new()


-- ENVY public setup
require("./envy")