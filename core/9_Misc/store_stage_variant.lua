-- Store current stage variant as a global variable

gm.variable_global_set("stage_variant", -1)

-- Hooks line 33 (to get value of `arg1` at some point)
local ptr = gm.get_script_function_address(gm.constants.stage_goto)
memory.dynamic_hook_mid("saveMod.stage_goto", {"rbp-D0h"}, {"RValue*"}, 0, ptr:add(0x1108), function(args)
    gm.variable_global_set("stage_variant", args[1].value)
end)

gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    gm.variable_global_set("stage_variant", -1)
end)