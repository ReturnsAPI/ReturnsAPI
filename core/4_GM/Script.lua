-- Script

-- This class is private, but Script wrappers are accessible by users.

Script = {}

local name_cache = setmetatable({}, {__mode = "k"}) -- Cache for script.name



-- ========== Static Methods ==========

Script.wrap = function(script)
    -- Input:   `object RValue` or Script wrapper
    -- Wraps:   { `yy_object_base` of `.type` 3, `cscriptref` }
    return Proxy.new({ script.yy_object_base, script.cscriptref }, metatable_script)
end



-- ========== Metatables ==========

metatable_script = {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "yy_object_base" then return Proxy.get(proxy)[1] end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        if k == "cscriptref" then return Proxy.get(proxy)[2] end
        if k == "name" then
            -- Check cache
            local name = name_cache[proxy]
            if not name then
                name = ffi.string(Proxy.get(proxy)[2].m_call_script.m_script_name):sub(12, -1)
                name_cache[proxy] = name
            end
            
            return name
        end
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "yy_object_base"
        or k == "RAPI"
        or k == "cscriptref"
        or k == "name" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        log.error("Script has no properties to set", 2)
    end,


    __call = function(proxy, self, other, ...)
        -- Cast `self` to `struct CInstance *` (if applicable)
        if self then
            local _type = Util.type(self)
            if      _type == "Struct"           then self = ffi.cast("struct CInstance *", self.value)
            elseif  instance_wrappers[_type]    then self = self.CInstance
            end
        end

        -- Cast `other` to `struct CInstance *` (if applicable)
        if other then
            local _type = Util.type(other)
            if      _type == "Struct"           then other = ffi.cast("struct CInstance *", other.value)
            elseif  instance_wrappers[_type]    then other = other.CInstance
            end
        end

        local args = table.pack(...)
        local holder = nil
        if args.n > 0 then holder = RValue.new_holder_scr(args.n) end

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