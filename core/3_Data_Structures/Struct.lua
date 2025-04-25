-- Struct

Struct = new_class()

local cinstance_cache = setmetatable({}, {__mode = "k"})    -- Cache for struct.CInstance



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Struct
--@optional     constructor | number    | The constructor to use.
--@optional     ...         |           | Arguments to pass to the constructor.
--[[
Returns a newly created GameMaker struct.
Can also create one from a constructor.
]]
Struct.new = function(constructor, ...)
    -- Blank struct
    if not constructor then
        local rvalue_struct = RValue.new(ffi.cast("struct YYObjectBase*", gm.gmf_struct_create()), RValue.Type.OBJECT)
        return Struct.wrap(rvalue_struct)
    end

    -- From constructor
    local args = table.pack(...)
    local holder = RValue.new_holder(1 + args.n)
    holder[0] = RValue.new(constructor)

    -- Populate holder
    for i = 1, args.n do
        holder[i] = RValue.from_wrapper(args[i])
    end

    local out = RValue.new(0)
    gmf["@@NewGMLObject@@"](out, nil, nil, args.n, holder)
    return Struct.wrap(out)
end


--@static
--@return       Struct
--@param        struct      | RValue or Struct wrapper  | The struct to wrap.
--[[
Returns a Struct wrapper containing the provided struct.
]]
Struct.wrap = function(struct)
    -- Input:   `object RValue` or Struct wrapper
    -- Wraps:   `yy_object_base` of `.type` 0
    if not Struct.is(struct) then log.error("Value is not a struct", 2) end
    local proxy = Proxy.new(struct.yy_object_base, metatable_struct)
    __ref_map:set_rvalue(
        RValue.new(struct.yy_object_base, RValue.Type.OBJECT),
        RValue.new(true)
    )
    return proxy
end


--@static
--@return       Struct
--@param        struct_yy   |           | `struct YYObjectBase*` pointing to a struct.
--[[
Returns a Struct wrapper containing the provided struct.
]]
Struct.wrap_yyobjectbase = function(struct_yy)
    -- Input:   `object RValue.yy_object_base` / `struct YYObjectBase*`
    -- Wraps:   `yy_object_base` of `.type` 0
    local proxy = Proxy.new(struct_yy, metatable_struct)
    __ref_map:set_rvalue(
        RValue.new(struct_yy, RValue.Type.OBJECT),
        RValue.new(true)
    )
    return proxy
end


--@static
--@return       bool
--@param        value       | RValue or Array wrapper   | The value to check.
--[[
Returns `true` if `value` is a struct, and `false` otherwise.
]]
Struct.is = function(value)
    -- `value` is either an `object RValue` or a Struct wrapper
    local _type = Util.type(value)
    if (_type == "cdata" and value.type == RValue.Type.OBJECT)
    or _type == "Struct" then return true end
    return false
end



-- ========== Instance Methods ==========

methods_struct = {

    get_keys = function(self)
        local holder = RValue.new_holder(1)
        holder[0] = RValue.new(self.value, RValue.Type.OBJECT)
        local out = RValue.new(0)
        gmf.variable_struct_get_names(out, nil, nil, 1, holder)
        local arr = Array.wrap(out)
        local keys = {}
        for i, v in ipairs(arr) do keys[i] = v end
        return keys
    end,


    print = function(self)
        local str = ""
        local keys = self:get_keys()
        for _, key in ipairs(keys) do
            str = str.."\n"..Util.pad_string_right(key, 32).." = "..Util.tostring(self[key])
        end
        print(str)
    end

}



-- ========== Metatables ==========

make_table_once("metatable_struct", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "yy_object_base" then return Proxy.get(proxy) end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        if k == "CInstance" then
            -- Check cache
            local cinstance = cinstance_cache[proxy]
            if not cinstance then
                cinstance = ffi.cast("struct CInstance *", Proxy.get(proxy))
                cinstance_cache[proxy] = cinstance
            end

            return cinstance
        end

        -- Methods
        if methods_struct[k] then
            return methods_struct[k]
        end
        
        -- Getter
        local holder = RValue.new_holder(2)
        holder[0] = RValue.new(Proxy.get(proxy), RValue.Type.OBJECT)
        holder[1] = RValue.new(k)
        local out = RValue.new(0)
        gmf.variable_struct_get(out, nil, nil, 2, holder)
        local wrapped = RValue.to_wrapper(out)

        -- If Script, automatically "bind"
        -- script as self/other
        if type(wrapped) == "table"
        and wrapped.RAPI == "Script" then
            wrapped.self = proxy
            wrapped.other = proxy
        end
        
        return wrapped
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "yy_object_base"
        or k == "RAPI"
        or k == "CInstance" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local holder = RValue.new_holder(3)
        holder[0] = RValue.new(Proxy.get(proxy), RValue.Type.OBJECT)
        holder[1] = RValue.new(k)
        holder[2] = RValue.from_wrapper(v)
        gmf.variable_struct_set(RValue.new(0), nil, nil, 3, holder)
    end,


    __len = function(proxy)
        return #proxy:get_keys()
    end,


    __pairs = function(proxy)
        local keys = proxy:get_keys()
        local i = 0
        return function(proxy)
            i = i + 1
            if i <= #keys then
                local k = keys[i]
                return k, proxy[k]
            end
        end, proxy, nil
    end,


    __gc = function(proxy)
        __ref_map:delete_rvalue(
            RValue.new(Proxy.get(proxy), RValue.Type.OBJECT)
        )
    end,


    __metatable = "RAPI.Wrapper.Struct"
})



-- Public export
__class.Struct = Struct