-- Show debug overlay

P.debug_overlay = P.debug_overlay or false

gui.add_to_menu_bar(function()
    P.debug_overlay = ImGui.Checkbox("Show GameMaker debug overlay", P.debug_overlay)
    gm.show_debug_overlay(P.debug_overlay)
end)