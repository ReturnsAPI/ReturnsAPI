-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"

gmf = require("ReturnOfModding-GLOBAL/gmf")


-- ENVY initial setup
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]


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


-- ENVY public setup
require("./envy")


-- Prevent anything in run_once() from running again
hotloaded = true


-- DEBUG
gui.add_imgui(function()
    if ImGui.Begin("ReturnsAPI Debug") then

        ImGui.Text("__rvalue_current:   "..__rvalue_current)
        ImGui.Text("#__ref_map:         "..#__ref_map)

        if ImGui.Button("Collect garbage") then
            collectgarbage()
        end

        if ImGui.Button("_mod_instance_number benchmark") then
            local foo = function(obj)
                local holder = RValue.new_holder_scr(1)
                holder[0] = RValue.new(obj)
                local out = RValue.new(0)
                gmf._mod_instance_number(nil, nil, out, 1, holder)
                return RValue.to_wrapper(out)
            end

            Util.benchmark(100000, gm._mod_instance_number, gm.constants.oP)
            Util.benchmark(100000, GM._mod_instance_number, gm.constants.oP)
            Util.benchmark(100000, foo, gm.constants.oP)
            Util.benchmark(100000, Instance.count, gm.constants.oP)
        end

        if ImGui.Button("instance_number benchmark") then
            local foo = function(obj)
                local holder = RValue.new_holder(1)
                holder[0] = RValue.new(obj)
                local out = RValue.new(0)
                gmf.instance_number(out, nil, nil, 1, holder)
                return RValue.to_wrapper(out)
            end

            Util.benchmark(100000, gm.instance_number, gm.constants.oP)
            Util.benchmark(100000, GM.instance_number, gm.constants.oP)
            Util.benchmark(100000, foo, gm.constants.oP)

            print(gm.instance_number(gm.constants.oP))
            print(GM.instance_number(gm.constants.oP))
        end

        if ImGui.Button("Spawn 100 Lemurians on player") then
            local p = Player.get_local()
            if p:exists() then
                local obj = Object.find("lizard", nil, "RAPI")
                for i = 1, 100 do obj:create(p.x, p.y) end
            end
        end

    end
    ImGui.End()
end)