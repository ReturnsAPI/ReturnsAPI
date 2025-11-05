-- Display version number under RoM's on title screen

Hook.add_post(RAPI_NAMESPACE, "gml_Object_oStartMenu_Draw_0", function(self, other)
    if self.menu_transition < 1 then
        self:draw_set_font_w(gm.constants.fntNormal)
        self:draw_set_color(Color(0x446790))
        self:draw_set_alpha(0.5 * (1 - self.menu_transition))
        self:draw_text_w(Global.___view_l_x + 6, Global.___view_l_y + 46, "ReturnsAPI v".._ENV._PLUGIN.version)
        self:draw_set_alpha(1)
    end
end)