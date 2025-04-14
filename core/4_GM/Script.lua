-- Script

Script = {}

run_once(function()
    __bind_id_count = 0
    __bind_id_to_func = {}
end)

local name_cache = setmetatable({}, {__mode = "k"})     -- Cache for script.name



-- ========== Static Methods ==========

--$static
--$return       Script
--$param        func        | function  | The function to bind.
--[[
Binds a Lua function to a GML script function and returns it.
]]
Script.bind = function(func)
    -- Create a new struct
    local struct = Struct.new()
    struct.__id = __bind_id_count

    -- Bind "dummy" function to struct
    -- When called, the struct will be the `self` parameter
    local method = GM.method(struct, gm.constants.function_dummy)
    method.self, method.other = struct, struct  -- Allows for the user to
                                                -- call the returned method

    -- Store `func`, which will be called
    -- when the binded dummy function is called
    __bind_id_to_func[__bind_id_count] = func
    __bind_id_count = __bind_id_count + 1

    -- Add to `__ref_map` to prevent GC
    __ref_map:set(method, true)

    return method
end


--$static
--$return       Script
--$param        script      | RValue or Script wrapper  | The script to wrap.
--[[
Returns a Script wrapper containing the provided script.
]]
Script.wrap = function(script)
    -- Input:   `object RValue` or Script wrapper
    -- Wraps:   { `cscriptref`, `yy_object_base` of `.type` 3 }
    return Proxy.new({
        script.cscriptref,
        script.yy_object_base,
        nil,    -- Stored `self`
        nil,    -- Stored `other`
    }, metatable_script)
end



-- ========== Metatables ==========

make_table_once("metatable_script", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "cscriptref" then return Proxy.get(proxy)[1] end
        if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
        if k == "yy_object_base" then return Proxy.get(proxy)[2] end
        if k == "name" then
            -- Check cache
            local name = name_cache[proxy]
            if not name then
                name = ffi.string(Proxy.get(proxy)[1].m_call_script.m_script_name):sub(12, -1)
                name_cache[proxy] = name
            end
            
            return name
        end

        -- Get stored self/other
        if k == "self"  then return Proxy.get(proxy)[3] end
        if k == "other" then return Proxy.get(proxy)[4] end
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

        -- Store self/other
        if k == "self"
        or k == "other" then
            local index = 3
            if k == "other" then index = 4 end

            local _type = Util.type(v)
            if      _type == "Struct"           then Proxy.get(proxy)[index] = ffi.cast("struct CInstance *", v.value)
            elseif  instance_wrappers[_type]    then Proxy.get(proxy)[index] = v.CInstance
            end
            return
        end

        log.error("Non-existent Script property '"..k.."'", 2)
    end,


    __call = function(proxy, ...)
        -- Get stored self/other
        local actual = Proxy.get(proxy)
        self    = actual[3]
        other   = actual[4]

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
})



-- ========== Hooks ==========

-- BIND LIMITATIONS:
-- * If `method` is called by game code against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

Memory.dynamic_hook("RAPI.function_dummy", "void*", {"YYObjectBase*", "void*", "RValue*", "int", "void*"}, gm.get_script_function_address(gm.constants.function_dummy),
    -- Pre-hook
    {function(ret_val, self, other, result, arg_count, args)
        local arg_count = arg_count:get()
        local args_typed = ffi.cast("struct RValue**", args:get_address())

        local wrapped_args = {}

        -- Wrap args
        for i = 0, arg_count - 1 do
            table.insert(wrapped_args, RValue.to_wrapper(args_typed[i]))
        end

        -- Call bound Lua function
        local fn = __bind_id_to_func[self.__id]
        fn(table.unpack(wrapped_args))

        -- TODO pass return value from fn to function_dummy? dunno if that's needed though
    end,

    -- Post-hook
    nil}
)



-- Public export
__class.Script = Script