-- Force stat recalculation *1 frame* after picking up an
-- equipment because this runs before RecalculateStats

Callback.add(RAPI_NAMESPACE, Callback.ON_PICKUP_COLLECTED, Callback.internal.FIRST, function(pickup, player)   
    if pickup.equipment_id < 0 then return end

    Alarm.add(RAPI_NAMESPACE, 1, function()
        if not Instance.exists(player) then return end
        player:queue_recalculate_stats()
    end)
end)