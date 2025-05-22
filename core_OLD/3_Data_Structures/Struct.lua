-- Struct

--[[
This class allows for manipulation of GameMaker structs.
Struct wrappers can be get/set to using dot syntax (e.g., `struct.my_key = 123`).
]]

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
        return Struct.wrap(gm.struct_create())
    end

    -- From constructor
    local args = table.pack(...)

    -- Unwrap args
    for i = 1, args.n do
        args[i] = Wrap.unwrap(args[i])
    end

    return Struct.wrap(gm["@@NewGMLObject@@"](table.unpack(args)))
end


--@static
--@return       Struct
--@param        struct      | `sol.YYObjectBase*` or Struct wrapper  | The struct to wrap.
--[[
Returns a Struct wrapper containing the provided struct.
]]
Struct.wrap = function(struct)
    -- Input:   `sol.YYObjectBase*` or Struct wrapper
    -- Wraps:   `sol.YYObjectBase*`
    -- if not Struct.is(struct) then log.error("Value is not a struct", 2) end
    local proxy = Proxy.new(Wrap.unwrap(struct), metatable_struct)
    -- __ref_map:set_rvalue(
    --     RValue.new(struct.yy_object_base, RValue.Type.OBJECT),
    --     RValue.new(true)
    -- )
    return proxy
end


--@static
--@return       bool
--@param        value       | RValue or Array wrapper   | The value to check.
--[[
Returns `true` if `value` is a struct, and `false` otherwise.
]]
-- Struct.is = function(value)
--     -- `value` is either an `object RValue` or a Struct wrapper
--     local _type = Util.type(value)
--     if (_type == "cdata" and value.type == RValue.Type.OBJECT)
--     or _type == "Struct" then return true end
--     return false
-- end      TODO



-- ========== Instance Methods ==========

--@section Instance Methods

methods_struct = {

    --@instance
    --@return       table
    --[[
    Returns a table of keys in use by the struct.
    ]]
    get_keys = function(self)
        local arr = Array.wrap(gm.variable_struct_get_names(self.value))
        local keys = {}
        for i, v in ipairs(arr) do keys[i] = v end
        return keys
    end,


    --@instance
    --[[
    Prints the struct.
    ]]
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

local metatable_name = "Struct"

make_table_once("metatable_struct", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(proxy) end
        if k == "RAPI" then return metatable_name end

        -- Methods
        if methods_struct[k] then
            return methods_struct[k]
        end
        
        -- Getter
        local wrapped = Wrap.wrap(gm.variable_struct_get(Proxy.get(proxy), Wrap.unwrap(k)))

        -- If Script, automatically "bind"
        -- script as self/other
        -- if type(wrapped) == "table"
        -- and wrapped.RAPI == "Script" then
        --     wrapped.self = proxy
        --     wrapped.other = proxy
        -- end      TODO

        return wrapped
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        gm.variable_struct_set(Proxy.get(proxy), Wrap.unwrap(k), Wrap.unwrap(v))
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
        -- __ref_map:delete_rvalue(
        --     RValue.new(Proxy.get(proxy), RValue.Type.OBJECT)
        -- )    TODO
    end,


    __metatable = "RAPI.Wrapper."..metatable_name
})



-- Public export
__class.Struct = Struct