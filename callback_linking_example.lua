-- Item

-- Linking to central callback system examples:


-- Colon syntax : metatable_item __index
{
    onHitProc = function(self, fn)
        -- item:onHitProc calls Callback.onHitProc:add

        -- Add closure that runs fn if item_count > 0
        -- Callback ID is returned; item callback can be removed via Callback.remove(id)
        return Callback.onHitProc:add(function(cb_args)
            if actor:item_count(self.value) > 0 then
                fn(cb_args)
            end
        end)
    end,


    onAcquired = function(self, fn)
        -- item:onAcquired calls Callback[self.on_acquired]:add

        return Callback[self.on_acquired]:add(fn)
    end
}


-- .add : metatable_item __index
{
    onHitProc = function(self, fn)
        -- item:onHitProc calls Callback.add(Callback.TYPE.onHitProc, ...)

        return Callback.add(Callback.TYPE.onHitProc, function(cb_args)
            if actor:item_count(self.value) > 0 then
                fn(cb_args)
            end
        end)
    end,


    onAcquired = function(self, fn)
        -- item:onAcquired calls Callback.add(self.on_acquired, ...)

        return Callback.add(self.on_acquired, fn)
    end
}