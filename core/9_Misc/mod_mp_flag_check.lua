-- Multiplayer Check

-- Prevent online play if there are any mods
-- that are not marked as online-safe

local settings

table.insert(_rapi_initialize, function()
    local file = TOML.new(_ENV["!guid"])
    settings = file:read() or {}

    if not settings.disableMPBlock then settings.disableMPBlock = false end

    -- Add toggle to disable online button blocking
    local options = ModOptions.new(_ENV["!guid"])
    local checkbox = options:add_checkbox("disableMPBlock")
    checkbox:add_getter(function()
        return settings.disableMPBlock
    end)
    checkbox:add_setter(function(value)
        settings.disableMPBlock = value
        file:write(settings)
    end)
end)


local text_x, text_y
local box_x, box_y, box_w, box_h
local initial_fadein

gm.post_script_hook(gm.constants._ui_draw_box_text, function(self, other, result, args)
    -- Find Online button
    if args[5].value == gm.translate("ui.title.startOnline") then

        -- Calculate correct position to draw text
        -- args 1 and 2 are text start
        -- args 3 and 4 are width and height
        -- Magic numbers are to account for button icon
        text_x = args[1].value + args[3].value/2 - 16
        text_y = args[2].value + args[4].value/2 - 2

        box_x, box_y, box_w, box_h = args[1].value, args[2].value, args[3].value, args[4].value

        initial_fadein = initial_fadein or 0
    end
end)

gm.post_code_execute("gml_Object_oStartMenu_Draw_73", function(self, other, code, result, flags)
    if not text_x then return end
    
    -- Check which mods are incompatible
    -- Only checks mods that import RAPI via .auto()
    local incomp = {}
    for env, t in pairs(__auto_setups) do
        if not t.mp then
            local arr = GM.string_split(env["!guid"], "-")
            table.insert(incomp, {
                author  = arr[1],
                name    = arr[2]
            })
        end
    end
    if #incomp <= 0 then
        self.menu[3].disabled = false
        return
    end
    
    -- Disable Online button
    if not settings.disableMPBlock then
        self.menu[3].disabled = true
    else self.menu[3].disabled = false
    end

    -- Get draw opacity of buttons
    -- Taken from oStartMenu_Draw_73 line 75
    local opacity = 1 - self.menu_transition

    -- Initial opacity fade-in on first title
    -- screen load (minor thing but looks better)
    if initial_fadein and (initial_fadein < 1) then
        initial_fadein = initial_fadein + 1/15  -- Hardcoded value that looks fine
        opacity = Math.easein(initial_fadein)
    end
    
    -- Show "x incompatible mod(s)" text
    gm.draw_set_font(1)
    gm.draw_set_halign(1)
    gm.draw_set_valign(1)
    local str = gm.translate("ui.numIncompatibleMods", #incomp)
    local col = {Color.ORANGE, Color.BLACK, Color.BLACK}
    for i = 3, 1, -1 do
        local c = col[i]
        gm.draw_text_color(text_x, text_y + i, str, c, c, c, c, opacity)
    end

    -- Show incompatible mod list
    -- when hovering over with mouse
    local mx, my = gm.variable_global_get("mouse_x"), gm.variable_global_get("mouse_y")
    if Util.bool(gm.point_in_rectangle(mx, my, box_x, box_y, box_x + box_w, box_y + box_h)) then
        local v_spacing = 16

        -- Box
        gm.draw_set_alpha(0.4 * opacity)
        local c = Color.BLACK
        gm.draw_rectangle_color(text_x - 136, text_y + 24, text_x + 136, text_y + 32 + (#incomp * v_spacing), c, c, c, c, false)

        -- Mod names
        gm.draw_set_alpha(1)
        gm.draw_set_valign(2)
        gm.draw_set_halign(0)
        local c = Color.WHITE
        for i = 1, #incomp do
            gm.draw_text_color(text_x - 128, text_y + 26 + (i * v_spacing), incomp[i].name:gsub("_", " "), c, c, c, c, opacity)
        end

        -- Mod authors
        gm.draw_set_halign(2)
        local c = Color.GRAY
        for i = 1, #incomp do
            gm.draw_text_color(text_x + 130, text_y + 26 + (i * v_spacing), "by "..incomp[i].author, c, c, c, c, opacity)
        end
    end
end)