-- Force stat recalculation 1 frame after picking up an
-- item/equipment because this runs before RecalculateStats

Callback.add(_ENV["!guid"], Callback.ON_PICKUP_COLLECTED, function(pickup, player)
    Alarm.new(_ENV["!guid"], 1, function()
        player:recalculate_stats()
    end)
end)