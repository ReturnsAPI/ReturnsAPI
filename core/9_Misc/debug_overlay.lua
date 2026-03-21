-- Show debug overlay

debug_overlay = debug_overlay or false

gui.add_to_menu_bar(function()
    debug_overlay = ImGui.Checkbox("Show GameMaker debug overlay", debug_overlay)
    gm.show_debug_overlay(debug_overlay)
end)