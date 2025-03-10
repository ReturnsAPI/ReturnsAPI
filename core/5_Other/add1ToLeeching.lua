-- Add back the +1 to Leeching Seed and Super Massive Leech

RecalculateStats.add("RAPI", function(actor, api)
    if actor:item_count(Item.find("leechingSeed", "ror")) > 0 then
        api.lifesteal_add(1)
    end

    -- TODO super massive leech
end)