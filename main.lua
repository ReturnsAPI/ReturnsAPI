-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"


-- ENVY initial setup
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]


-- Remove internal RAPI hooks on hotload
-- This needs to be called before loading core
if run_on_hotload then
    run_on_hotload(function()
        local namespace = _ENV["!guid"]
        run_clear_namespace_functions(namespace)    -- in Internal.lua
    end)
end


-- Load core
local ignore_these = {
    ["data"]            = true,
    ["old_midhook_stuff"]  = true,
    -- ["2_GM"]            = true,
    -- ["3_General"]       = true,
    -- ["4_Class_Arrays"]  = true,
    -- ["5_Instances"]     = true
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


-- Run some functions after core load
for _, fn in ipairs(_run_after_core) do
    fn()
end


-- ENVY public setup
require("./envy")


-- Prevent anything in run_once() from running again
hotloaded = true