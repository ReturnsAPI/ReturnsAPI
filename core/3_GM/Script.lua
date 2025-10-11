-- Script

--[[
This class provides functionality for calling GameMaker script functions.

Calling one directly will use the `self` and `other` binded to the wrapper.
If you need to directly pass a struct/instance into `self`/`other`, use `script.SO`.

E.g.,
```lua
-- `script` is some Script wrapper
-- The first two arguments are `self, other`
script.SO(instance, instance, arg1, arg2)
```

Getting a script function from a Struct or
Instance will automatically bind it as `self`/`other`.

E.g.,
```lua
-- Automatically binds `self_struct` as self/other when calling
-- `skill_start_cooldown` since it was gotten from `self_struct`
self_struct.skill_start_cooldown()
```
]]

Script = {}

run_once(function()
    __bind_id_count = 0
    __bind_id_to_func = {}
    __self_other_cache = setmetatable({}, {__mode = "k"})   -- Stores binded self/other
end)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`/`cscriptref`| CScriptRef            | *Read-only.* The `sol.CScriptRef*` being wrapped
`RAPI`              | string                | *Read-only.* The wrapper name.
`name`              | string                | *Read-only.* The script name.
`self`              | Struct or Instance    | The struct/instance binded as `self`; used when calling.
`other`             | Struct or Instance    | The struct/instance binded as `other`; used when calling.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Script
--@param        func        | function  | The function to bind.
--[[
Binds a Lua function to a GML script function and returns it.
]]
Script.bind = function(func)
    -- Create a new struct
    local struct = Struct.new{
        __id = __bind_id_count
    }

    -- Bind "dummy" function to struct
    local cscriptref = gm.method(struct.value, gm.constants.function_dummy)
    local method = Script.wrap(cscriptref)

    -- When called, the struct will be the `self` parameter
    method.self, method.other = struct, struct  -- Allows for the user to
                                                -- call the returned method

    -- Store `func`, which will be called
    -- when the binded dummy function is called
    __bind_id_to_func[__bind_id_count] = func
    __bind_id_count = __bind_id_count + 1

    -- Add to `__ref_map` to prevent GC
    -- * Doesn't seem needed anymore
    -- __ref_map:set(cscriptref, true)

    return method
end


--@static
--@return       Script
--@param        script      | `sol.CScriptRef*` or Script wrapper  | The script to wrap.
--[[
Returns a Script wrapper containing the provided script.
]]
Script.wrap = function(script)
    -- Input:   `sol.CScriptRef*` Script wrapper
    -- Wraps:   `sol.CScriptRef*`
    local proxy = make_proxy(Wrap.unwrap(script), metatable_script)
    __self_other_cache[proxy] = {nil, nil}    -- self, other (sol.CInstance*)
    return proxy
end



-- ========== Metatables ==========

local wrapper_name = "Script"

make_table_once("metatable_script", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI"  then return wrapper_name end
        if k == "name"  then return __proxy[proxy].script_name:sub(12, -1) end

        -- Get stored self/other
        if k == "self"  then return __self_other_cache[proxy][1] end
        if k == "other" then return __self_other_cache[proxy][2] end

        -- Call with manual self/other
        if k == "SO" then
            return function(self, other, ...)
                local args = table.pack(...)

                -- Unwrap args
                for i = 1, args.n do
                    args[i] = Wrap.unwrap(args[i])
                end

                return Wrap.wrap(__proxy[proxy](Wrap.unwrap(self), Wrap.unwrap(other), table.unpack(args)))
            end
        end
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "name"
        or k == "SO" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Store self/other
        if k == "self"
        or k == "other" then
            local index = ((k == "self") and 1) or 2

            -- Convert v into `sol.CInstance*` to store
            local cinstance = Wrap.unwrap(v)
            __self_other_cache[proxy][index] = cinstance
            return
        end

        log.error("Non-existent Script property '"..k.."'", 2)
    end,


    __call = function(proxy, ...)
        -- Get stored self/other
        local cached = __self_other_cache[proxy]
        local self   = cached[1]
        local other  = cached[2]

        local args = table.pack(...)

        -- Unwrap args
        for i = 1, args.n do
            args[i] = Wrap.unwrap(args[i])
        end

        return Wrap.wrap(__proxy[proxy](self, other, table.unpack(args)))
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

-- BIND LIMITATIONS:
-- * If `method` is called by game code against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

gm.post_script_hook(gm.constants.function_dummy, function(self, other, result, args)
	if gm.is_struct(self) then

        -- Get function binded to __id
		local fn = __bind_id_to_func[self.__id]

		if fn then
			local arg_table = {}
			for i = 1, #args do
				table.insert(arg_table, args[i].value)
			end
            
            -- Call function with args
            -- and put return value into result (if applicable)
			local ret = fn(table.unpack(arg_table))
			if ret then result.value = ret end
		end
	end
end)



-- Public export
__class.Script = Script