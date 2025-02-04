-- Item

-- Linking to central callback system example:

-- metatable_item __index
{
    onHitProc = function(self, fn)
        -- Add closure that runs fn if item_count > 0
        Callback.onHitProc:add(function(cb_args)
            if actor:item_count(self.value) > 0 then
                fn(cb_args)
            end
        end)
    end
}