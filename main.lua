-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"


-- ENVY initial setup
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]


-- TODO
-- Remove internal RAPI hooks on hotload
-- This needs to be called before loading core
-- if run_on_hotload then
--     run_on_hotload(function()
--         local namespace = _ENV["!guid"]
--         if Callback         then Callback.remove_all(namespace) end
--         if Hook             then Hook.remove_all(namespace) end
--         if Initialize       then Initialize.internal.remove_all(namespace) end
--         if RecalculateStats then RecalculateStats.remove_all(namespace) end
--         if DamageCalculate  then DamageCalculate.remove_all(namespace) end
--         if Alarm            then Alarm.remove_all(namespace) end
--         if Object           then Object.remove_all_serializers(namespace) end
--     end)
-- end


-- Load core
local ignore_these = {
    ["data"]            = true,
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