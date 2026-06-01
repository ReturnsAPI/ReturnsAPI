-- HUD Draw Callback Fix
-- by Onyx

-- Fixes `*_HUD_DRAW` callbacks behaving differently if zoom scale == HUD scale

gm.pre_script_hook(gm.constants.hud_draw_start, function(self, other, result, args)
    self:ui_force_render_zoom(nil, nil, nil, nil, Global.current_hud_scale)
    Global.hud_is_being_drawn_to_render_surf = true
    result.value = true
    return false
end)

gm.pre_script_hook(gm.constants.hud_draw_stop, function(self, other, result, args)
    Global.hud_is_being_drawn_to_render_surf = false
    gm.ui_reset_render_zoom()
    return false
end)