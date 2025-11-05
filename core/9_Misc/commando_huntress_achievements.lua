-- Add achievements for Commando and Huntress to put their survivor-specific achievements under

table.insert(_rapi_initialize, function()
    local list = List.wrap(Global.achievement_display_list)

    unlock_commando = Achievement.new("ror", "unlock_commando")
    unlock_commando:set_unlock_survivor(Survivor.find("commando", "ror", true))
    unlock_commando.group = 1
    unlock_commando:add_progress(1)
    list:delete_value(unlock_commando)
    list:insert(1, unlock_commando)

    unlock_huntress = Achievement.new("ror", "unlock_huntress")
    unlock_huntress:set_unlock_survivor(Survivor.find("huntress", "ror", true))
    unlock_huntress.group = 1
    unlock_huntress:add_progress(1)
    list:delete_value(unlock_huntress)
    list:insert(2, unlock_huntress)

    for _, identifier in ipairs{
        "unlock_cape",
        "unlock_mace",
        "unlock_commando_x2",
        "unlock_commando_c2",
        "unlock_commando_v2",
        "unlock_commando_skin_a",
        "unlock_threader",
        "unlock_commando_skin_p",
        "unlock_commando_skin_s"
    } do
        Achievement.find(identifier, "ror", true).parent_id = unlock_commando
    end

    for _, identifier in ipairs{
        "unlock_scarf",
        "unlock_instincts",
        "unlock_huntress_z2",
        "unlock_huntress_x2",
        "unlock_huntress_c2",
        "unlock_voltaic_mitt",
        "unlock_huntress_skin_p",
        "unlock_huntress_skin_s"
    } do
        Achievement.find(identifier, "ror", true).parent_id = unlock_huntress
    end
end)


Hook.add_pre(RAPI_NAMESPACE, gm.constants.achievement_on_unlocked, function(self, other, result, args)
    -- Prevent Divine Intervention unlock from the two achievements above
    if (args[1].value == unlock_commando.value)
    or (args[1].value == unlock_huntress.value) then
        return false
    end
end)


Hook.add_pre(RAPI_NAMESPACE, gm.constants["achievement_unlocked@gml_Object_oInit_Create_0"], function(self, other, result, args)
    -- Prevent unlock being added to display queue for the two achievements above
    if (args[1].value == unlock_commando.value)
    or (args[1].value == unlock_huntress.value) then
        return false
    end
end)