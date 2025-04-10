-- Script

-- This class is private, but Script wrappers are accessible by users.

Script = {}

local name_cache = setmetatable({}, {__mode = "k"}) -- Cache for script.name



-- ========== Static Methods ==========

Script.wrap = function(script)
    -- Input:   `object RValue` or Script wrapper
    -- Wraps:   `yy_object_base` of `.type` 3 (`.cscriptref`)
    return Proxy.new(struct.yy_object_base, metatable_script)
end



-- ========== Metatables ==========

metatable_script = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "yy_object_base" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        if k == "name" then
            -- Check cache
            local name = name_cache[proxy]
            if not name then
                name = ffi.string(Proxy.get(proxy).cscriptref.m_call_script.m_script_name):sub(12, -1)
                name_cache[proxy] = name
            end
            
            return name
        end
    end,


    __newindex = function(proxy, k, v)
        log.error("Script has no properties to set", 2)
    end,


    __call = function(proxy, self, other, ...)
        -- Get `struct CInstance` for self and other if not nil
        -- Assumes self and other are Instance wrappers
        if self then self = self.CInstance end
        if other then other = other.CInstance end

        local args = table.pack(...)
        local holder = RValue.new_holder_scr(args.n)

        -- Populate holder
        for i = 1, args.n do
            holder[i - 1] = RValue.from_wrapper(args[i])
        end

        local out = RValue.new(0)
        gmf[proxy.name](self, other, out, args.n, holder)
        return RValue.to_wrapper(out)
    end,

    
    __metatable = "RAPI.Wrapper.Script"
}