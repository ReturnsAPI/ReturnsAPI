-- Multiplayer-safe check

-- Prevent local/online multiplayer if there are any mods
-- that are not marked as local/online-safe

local string = string
local table  = table
local math   = math
local gm     = gm
local P      = P
local Util   = Util
local Color  = Color

local settings

run_on_initialize(function()
    local file = TOML.new(RAPI_NAMESPACE)
    settings = file:read() or {}

    if settings.disableMPBlock == nil then settings.disableMPBlock = false end

    -- Add toggle to disable button blocking
    local options = ModOptions.new(RAPI_NAMESPACE)
    local checkbox = options:add_checkbox("disableMPBlock")
    checkbox:add_getter(function()
        return settings.disableMPBlock
    end)
    checkbox:add_setter(function(value)
        settings.disableMPBlock = value
        file:write(settings)
    end)
end)

local b_local  = {}
local b_online = {}

gm.post_script_hook(gm.constants._ui_draw_box_text, function(self, other, result, args)
    -- Find buttons and calculate correct draw positions
    -- args 1 and 2 are text start
    -- args 3 and 4 are width and height
    -- Magic numbers are to account for button icon
    local arg1 = args[1].value
    local arg2 = args[2].value
    local arg3 = args[3].value
    local arg4 = args[4].value
    local str  = args[5].value
    
    if str == gm.translate("ui.title.startLocal") then
        b_local.text_x = arg1 + arg3/2 - 16
        b_local.text_y = arg2 + arg4/2 - 2

        b_local.box_x, b_local.box_y, b_local.box_w, b_local.box_h
        = arg1, arg2, arg3, arg4

        b_local.initial_fadein = b_local.initial_fadein or 0
    
    elseif str == gm.translate("ui.title.startOnline") then
        b_online.text_x = arg1 + arg3/2 - 16
        b_online.text_y = arg2 + arg4/2 - 2

        b_online.box_x, b_online.box_y, b_online.box_w, b_online.box_h
        = arg1, arg2, arg3, arg4

        b_online.initial_fadein = b_online.initial_fadein or 0

    end
end)

gm.post_code_execute("gml_Object_oStartMenu_Draw_73", function(self, other, code, result, flags)
    local menu_local  = self.menu[2]
    local menu_online = self.menu[3]
    
    -- Check which mods are incompatible
    -- Only checks mods that have imported RAPI
    local incomp_local, incomp_online = {}, {}
    for namespace, data in pairs(P.mod_data_ns) do
        if not data.mp then
            local t_guid = string.split(data.env["!guid"], "-")
            local m_data = {
                author = t_guid[1],
                name   = t_guid[2],
            }
            if not data.mp_local  then table.insert(incomp_local,  m_data) end
            if not data.mp_online then table.insert(incomp_online, m_data) end
        end
    end

    local has_incomp_local, has_incomp_online
       = #incomp_local > 0, #incomp_online > 0

    if not has_incomp_local  then menu_local.disabled  = false end
    if not has_incomp_online then menu_online.disabled = false end

    -- Exit if there are no incompatibilities
    if not has_incomp_local and not has_incomp_online then return end

    local text_col = {Color.ORANGE, Color.BLACK, Color.BLACK}

    -- Disable local button and draw "x incompatible mod(s)" text
    if has_incomp_local and b_local.text_x then

        -- Button
        if not settings.disableMPBlock then
             menu_local.disabled = true
        else menu_local.disabled = false
        end

        -- Get draw opacity of buttons
        -- (Taken from `oStartMenu_Draw_73` line 75)
        b_local.opacity = 1 - self.menu_transition

        -- Initial opacity fade-in on first title
        -- screen load (minor thing but looks better)
        if b_local.initial_fadein and (b_local.initial_fadein < 1) then
            b_local.initial_fadein = b_local.initial_fadein + 1/15  -- Hardcoded value that looks fine
            b_local.opacity = math.easein(b_local.initial_fadein)
        end

        -- Text
        local str = gm.translate("ui.numIncompatibleMods", #incomp_local)
        gm.scribble_set_blend(Color.WHITE, math.clamp(b_local.opacity, 0, 1))
        for i = 3, 1, -1 do
            local c = text_col[i]
            gm.scribble_set_starting_format("fntNormal", c, 1)
            gm.scribble_draw(b_local.text_x, b_local.text_y + i - 7, str)
        end
        gm.scribble_reset(true)
    end

    -- Disable online button and draw "x incompatible mod(s)" text
    if has_incomp_online and b_online.text_x then

        -- Button
        if not settings.disableMPBlock then
             menu_online.disabled = true
        else menu_online.disabled = false
        end

        -- Get draw opacity of buttons
        -- (Taken from `oStartMenu_Draw_73` line 75)
        b_online.opacity = 1 - self.menu_transition

        -- Initial opacity fade-in on first title
        -- screen load (minor thing but looks better)
        if b_online.initial_fadein and (b_online.initial_fadein < 1) then
            b_online.initial_fadein = b_online.initial_fadein + 1/15  -- Hardcoded value that looks fine
            b_online.opacity = math.easein(b_online.initial_fadein)
        end

        -- Text
        local str = gm.translate("ui.numIncompatibleMods", #incomp_online)
        gm.scribble_set_blend(Color.WHITE, math.clamp(b_online.opacity, 0, 1))
        for i = 3, 1, -1 do
            local c = text_col[i]
            gm.scribble_set_starting_format("fntNormal", c, 1)
            gm.scribble_draw(b_online.text_x, b_online.text_y + i - 7, str)
        end
        gm.scribble_reset(true)
    end

    local mx, my = gm.variable_global_get("mouse_x"), gm.variable_global_get("mouse_y")

    -- Show local incompatible mod list when hovering over with mouse
    if has_incomp_local and b_local.text_x then
        if Util.bool(gm.point_in_rectangle(
            mx,
            my,
            b_local.box_x,
            b_local.box_y,
            b_local.box_x + b_local.box_w,
            b_local.box_y + b_local.box_h
        )) then
            local v_spacing = 16

            -- Box
            gm.draw_set_alpha(0.4 * b_local.opacity)
            local c = Color.BLACK
            gm.draw_rectangle_color(b_local.text_x - 136, b_local.text_y + 24, b_local.text_x + 136, b_local.text_y + 32 + (#incomp_local * v_spacing), c, c, c, c, false)

            -- Mod names
            gm.draw_set_alpha(1)
            gm.draw_set_valign(2)
            gm.draw_set_halign(0)
            local c = Color.WHITE
            for i = 1, #incomp_local do
                gm.draw_text_color(b_local.text_x - 128, b_local.text_y + 26 + (i * v_spacing), incomp_local[i].name:gsub("_", " "), c, c, c, c, b_local.opacity)
            end

            -- Mod authors
            gm.draw_set_halign(2)
            local c = Color.GRAY
            for i = 1, #incomp_local do
                gm.draw_text_color(b_local.text_x + 130, b_local.text_y + 26 + (i * v_spacing), "by "..incomp_local[i].author, c, c, c, c, b_local.opacity)
            end
        end
    end

    -- Show online incompatible mod list when hovering over with mouse
    if has_incomp_online and b_online.text_x then
        if Util.bool(gm.point_in_rectangle(
            mx,
            my,
            b_online.box_x,
            b_online.box_y,
            b_online.box_x + b_online.box_w,
            b_online.box_y + b_online.box_h
        )) then
            local v_spacing = 16

            -- Box
            gm.draw_set_alpha(0.4 * b_online.opacity)
            local c = Color.BLACK
            gm.draw_rectangle_color(b_online.text_x - 136, b_online.text_y + 24, b_online.text_x + 136, b_online.text_y + 32 + (#incomp_online * v_spacing), c, c, c, c, false)

            -- Mod names
            gm.draw_set_alpha(1)
            gm.draw_set_valign(2)
            gm.draw_set_halign(0)
            local c = Color.WHITE
            for i = 1, #incomp_online do
                gm.draw_text_color(b_online.text_x - 128, b_online.text_y + 26 + (i * v_spacing), incomp_online[i].name:gsub("_", " "), c, c, c, c, b_online.opacity)
            end

            -- Mod authors
            gm.draw_set_halign(2)
            local c = Color.GRAY
            for i = 1, #incomp_online do
                gm.draw_text_color(b_online.text_x + 130, b_online.text_y + 26 + (i * v_spacing), "by "..incomp_online[i].author, c, c, c, c, b_online.opacity)
            end
        end
    end
end)