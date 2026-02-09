-- Store current stage variant as a global variable
-- Hooks line 33 (to get value of `arg1` at some point)
local ptr = gm.get_script_function_address(gm.constants.stage_goto)
memory.dynamic_hook_mid("saveMod.stage_goto", {"rbp-D0h"}, {"RValue*"}, 0, ptr:add(0x1108), function(args)
    gm.variable_global_set("stage_variant", args[1].value)
end)