-- Fix incorrect damage numbers related to Sniper's spotter drone
-- Somehow fixes it for mp too

-- TODO fix mid hook

-- local ptr = gm.get_script_function_address(gm.constants.damager_calculate_damage)   -- 0x0000000 140B154D0

-- memory.dynamic_hook_mid("RAPI.Fix.sniper_crit_number", {"rbp+20h"}, {"RValue*"}, 0, ptr:add(0x6A0), function(args)
--     -- `rbp+20h` is `damage_fake`
--     args[1].value = args[1].value * 2
-- end)