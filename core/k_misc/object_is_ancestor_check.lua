-- Bounds check for `gm.object_is_ancestor`

local custom_start = Object.CUSTOM_START

gm.pre_script_hook(gm.constants.object_is_ancestor, function(self, other, result, args)
    if args[1].value >= custom_start then
        result.value = false
        return false
    end
end)