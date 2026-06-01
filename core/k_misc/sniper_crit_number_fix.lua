-- Fix incorrect damage numbers related to Sniper's spotter drone
-- (Damage number not getting doubled on guaranteed crit)
-- Somehow fixes it for mp too

local ptr = gm.get_script_function_address(gm.constants.damager_calculate_damage)

-- Hooks line 11 (inside the `with (oSniperDrone)` and its conditional)
memory.dynamic_hook_mid("RAPI.Fix.sniper_crit_number", {"rbp+180h"}, {"RValue*"}, 0, ptr:add(0x5EF), function(args)
    -- damage_fake
    args[1].value = args[1].value * 2
end)