-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"

gmf = require("ReturnOfModding-GLOBAL/gmf")


-- ENVY initial setup
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]


-- Remove internal RAPI hooks on hotload
-- This needs to be called before loading core
if run_on_hotload then
    run_on_hotload(function()
        local namespace = _ENV["!guid"]
        if Callback         then Callback.remove_all(namespace) end
        if Hook             then Hook.remove_all(namespace) end
        if Initialize       then Initialize.internal.remove_all(namespace) end
        if RecalculateStats then RecalculateStats.remove_all(namespace) end
        if DamageCalculate  then DamageCalculate.remove_all(namespace) end
        if Alarm            then Alarm.remove_all(namespace) end
        if Object           then Object.remove_all_serializers(namespace) end
    end)
end


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
spawning = true
invincibility = false

gui.add_imgui(Util.jit_off(function()
    if ImGui.Begin("ReturnsAPI Debug") then

        ImGui.Text("__rvalue_current:   "..__rvalue_current)
        ImGui.Text("#__ref_map:         "..#__ref_map)

        if ImGui.Button("Collect garbage") then
            collectgarbage()
        end

        if ImGui.Button("Spawn 100 Lemurians on player") then
            local p = Player.get_local()
            if Instance.exists(p) then
                local obj = Object.find("lizard", nil, "RAPI")
                for i = 1, 100 do obj:create(p.x, p.y) end
            end
        end

        if ImGui.Button("Toggle spawning: "..tostring(spawning)) then
            spawning = not spawning
        end

        if ImGui.Button("Toggle invincibility: "..tostring(invincibility)) then
            invincibility = not invincibility
        end

        if ImGui.Button("Print memory.game_base_address") then
            print(memory.game_base_address)
            -- 1.4070007155917e+14
            -- 0x7FF749C90002
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

    end
    ImGui.End()
end))

Hook.post(_ENV["!guid"], "__input_system_tick", function(self, other, result, args)
    if not spawning then
        local director = Instance.find(gm.constants.oDirectorControl)
        if Instance.exists(director) then director:alarm_set(1, 60) end
    end

    if invincibility then
        local p = Player.get_local()
        if Instance.exists(p) then p.invincible = 3 end
    end
end)


-- Draw debug info
-- Toggle in top ImGui bar under this mod

local debug_show_info = false
gui.add_to_menu_bar(Util.jit_off(function()
    local value, pressed = ImGui.Checkbox("Show debug info", debug_show_info)
    if pressed then debug_show_info = value end
end))

local _scale
local _scale2
local function scale(n) return (n or 1) * _scale end
local function scale2(n) return (n or 1) * _scale2 end

local y = 100
local function draw_info(text, value)
    -- Draw info on line
    local sc_y = scale(y)
    local sc = scale()
    GM.draw_text_transformed(scale(25), sc_y, text, sc, sc, 0)
    GM.draw_text_transformed(scale(175), sc_y, value, sc, sc, 0)

    -- Increment y for next line
    y = y + 15
end

Hook.post(_ENV["!guid"], "gml_Object_oInit_Draw_64", function(self, other)
    if not debug_show_info then return end

    _scale = GM.variable_global_get("___ui_mode_zoom_scale")
    _scale2 = GM.variable_global_get("current_zoom_scale")
    
    -- Save old draw properties
    local og_col = GM.draw_get_color()
    local og_halign = GM.draw_get_halign()
    local og_valign = GM.draw_get_valign()
    local og_font = GM.draw_get_font()

    -- Set draw properties
    GM.draw_set_halign(0)
    GM.draw_set_valign(0)
    GM.draw_set_font(gm.constants.fntNormal)
    GM.draw_set_color(Color.WHITE)
    y = 100


    -- Populate with debug info
    local info_table = {
        {"__rvalue_current:",   __rvalue_current},
        {"#__ref_map:",         #__ref_map},
    }

    
    -- Draw info
    for _, v in ipairs(info_table) do
        draw_info(v[1], v[2])
    end

    -- Reset old draw properties
    GM.draw_set_color(og_col)
    GM.draw_set_alpha(1)
    GM.draw_set_halign(og_halign)
    GM.draw_set_valign(og_valign)
    GM.draw_set_font(og_font)
end)