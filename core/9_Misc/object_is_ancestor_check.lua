-- Bounds check for `gm.object_is_ancestor`

gm.pre_script_hook(gm.constants.object_is_ancestor, function(self, other, result, args)
    if args[1].value >= Object.CUSTOM_START then
        result.value = false
        return false
    end
end)