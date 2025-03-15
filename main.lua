-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"

gmf = require("ReturnOfModding-GLOBAL/gmf")
require("./jit_safe")


-- ENVY initial setup
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]


-- Load core
_CLASS = {}         -- All public classes should self-populate these two tables
_CLASS_MT = {}      -- Optional: The metatable to set for the class when copying in envy.lua
_CLASS_MT_MAKE = {} -- Optional: The metatable builder to call when copying in envy.lua; first argument should be `namespace`

local ignore_these = {
    ["data"]            = true,
    -- ["2_GM"]            = true,
    -- ["3_General"]       = true,
    ["4_Class_Arrays"]  = true,     -- TODO reenable and test these
    ["5_Instances"]     = true
}

local dirs = path.get_directories(PATH.."core")
for _, dir in ipairs(dirs) do
    if not ignore_these[path.filename(dir)] then
        local files = path.get_files(dir)
        for _, file in ipairs(files) do
            require(file)
        end
    end
end


-- ENVY public setup
require("./envy")