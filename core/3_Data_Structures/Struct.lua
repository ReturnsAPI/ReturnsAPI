-- Struct

--[[
This class allows for manipulation of GameMaker structs.
Struct wrappers can be get/set to using dot syntax (e.g., `struct.my_key = 123`).
]]

Struct = new_class()

local cinstance_cache = setmetatable({}, {__mode = "k"})    -- Cache for struct.cinstance


-- Wrapper types that are Structs
struct_wrappers = {
    Struct      = true,
    AttackInfo  = true,
    HitInfo     = true
}



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`/`cinstance` |           | *Read-only.* The `sol.YYObjectBase*` being wrapped.
`RAPI`              | string    | *Read-only.* The wrapper name.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Struct
--@optional     table       | table     | A Lua table to create the struct from.
--@return       Struct
--@param        constructor | number    | The constructor to use.
--@optional     ...         |           | Arguments to pass to the constructor. <br>Alternatively, a table may be provided.
--[[
Returns a newly created GameMaker struct.
Can also create one from a constructor.
]]
Struct.new = function(constructor, ...)
    -- Blank struct
    if not constructor then
        return Struct.wrap(gm.struct_create())
    end

    -- Create from Lua table
    if type(constructor) == "table" then
        local struct = gm.struct_create()
        for k, v in pairs(constructor) do
            struct[k] = Wrap.unwrap(v, true)
        end
        return Struct.wrap(struct)
    end

    -- From constructor
    local args = table.pack(...)
    if type(args[1]) == "table" and (not args[1].RAPI) then args = args[1] end

    -- Unwrap args
    for i = 1, args.n do
        args[i] = Wrap.unwrap(args[i], true)
    end

    return Struct.wrap(gm["@@NewGMLObject@@"](constructor, table.unpack(args)))
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
    struct = Wrap.unwrap(struct)
    return make_proxy(struct, metatable_struct)
end



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

local wrapper_name = "Struct"

make_table_once("metatable_struct_class", {
    __call = function(t, ...)
        return Struct.new(...)
    end,


    __metatable = "RAPI.Class."..wrapper_name
})
setmetatable(Struct, metatable_struct_class)


make_table_once("metatable_struct", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "cinstance" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_struct[k] then
            return methods_struct[k]
        end
        
        -- Getter
        local ret = Wrap.wrap(gm.variable_struct_get(__proxy[proxy], k))

        -- If Script, automatically "bind"
        -- to script as self/other
        if type(ret) == "table"
        and ret.RAPI == "Script" then
            ret.self = proxy
            ret.other = proxy
        end

        return ret
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "cinstance"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        gm.variable_struct_set(__proxy[proxy], k, Wrap.unwrap(v, true))
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


    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- Public export
__class.Struct = Struct
__class_mt.Struct = metatable_struct_class