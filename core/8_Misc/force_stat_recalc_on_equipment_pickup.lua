-- Force stat recalculation *1 frame* after picking up an
-- equipment because this runs before RecalculateStats

Callback.add(_ENV["!guid"], Callback.ON_PICKUP_COLLECTED, function(pickup, player)   
    if pickup.equipment_id < 0 then return end

    Alarm.new(_ENV["!guid"], 1, function()
        if not Instance.exists(player) then return end
        player:queue_recalculate_stats()
    end)
end)