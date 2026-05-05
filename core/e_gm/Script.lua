-- Script

---@class Script
Script = {}
C.Script = Script

run_on_initial_load(function()
    P.script_binded_functions = {}  ---@type table<integer, function> Maps bind IDs to functions.
    P.script_binded_counter   = 0   -- Take before incrementing
    P.script_SO               = {}  ---@type table<Script, table> Stores `self`/`other` of Scripts. <br>`[1]` - `self` <br>`[2]` - `other`
end)

local proxy = P.proxy
local metatable
local script_binded_functions = P.script_binded_functions
local script_SO = P.script_SO

local select           = select
local getmetatable     = getmetatable
local string_sub       = string.sub
local table_unpack     = table.unpack
local gm_call          = gm.call
local gm_method        = gm.method
local gm_struct_create = gm.struct_create
local wrap             = Wrap.wrap
local unwrap           = Wrap.unwrap
local unwrap_args      = unwrap_args

local args_holders = {}     -- Reusable tables for arg holders
local args_values  = {}     -- Reusable tables for arg values
local args_holder_rsp = 0   -- Index of most recently used; increment before taking
local args_value_rsp  = 0   -- Index of most recently used; increment before taking
for i = 1, 256 do
    args_holders[i] = {}
    args_values[i]  = {}
end


-- ========== Static Methods ==========

--[[
Binds a Lua function to a GameMaker script and returns it.
]]
---@param fn function The function to bind.
---@return Script
Script.bind = function(fn)
    local id = P.script_binded_counter
    local struct = gm_struct_create()
    struct.__id = id

    -- Bind `function_dummy` to the struct
    local cscriptref = gm_method(struct.value, gm.constants.function_dummy)
    local script = Script.wrap(cscriptref)

    -- When called, the struct will be the `self` parameter
    -- Allows for the user to call the returned script
    script.self  = struct
    script.other = struct

    -- Store `fn`, which will be called
    -- when the binded `function_dummy` is called
    script_binded_functions[id] = fn
    P.script_binded_counter = id + 1

    return script
end

--[[
Returns a Script wrapper containing the provided script.
]]
---@param script Script | sol.CScriptRef* The script to wrap.
---@return Script
Script.wrap = function(script)
    local t = new_proxy(unwrap(script), metatable)
    script_SO[t] = {}
    return t
end


-- ========== Metatables ==========

---@class Script
---@field value sol.CScriptRef*
---@field RAPI string
---@field name string
---@field script_name string
---@field self sol.YYObjectBaseLuaWrapper | sol.CInstance* | nil
---@field other sol.YYObjectBaseLuaWrapper | sol.CInstance* | nil

local mt_name = "Script"

W.Script = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        if k == "name" or k == "script_name" then
            return string_sub(proxy[t].script_name, 12, -1)
        end

        -- Get `self`/`other`
        if k == "self"  then return script_SO[t][1] end
        if k == "other" then return script_SO[t][2] end

        -- Call with manual `self`/`other`
        if k == "SO" then
            return function(self, other, ...)
                local n = select("#", ...)
                if n == 0 then return wrap(proxy[t](unwrap(self), unwrap(other))) end
                if n == 1 then return wrap(proxy[t](unwrap(self), unwrap(other), unwrap(...))) end
                return wrap(proxy[t](unwrap(self), unwrap(other), unwrap_args(n, ...)))
            end
        end
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "RAPI"
        or k == "name"
        or k == "script_name" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Set `self`/`other` (unwrapped)
        if k == "self"
        or k == "other" then
            local index = (k == "self" and 1) or 2
            local cinstance = unwrap(v)  -- May also be a Struct
            script_SO[t][index] = cinstance
            return
        end

        log.error("Non-existent "..mt_name.." property '"..k.."'", 2)
    end,

    __call = function(t, ...)
        local store = script_SO[t]
        local self  = store[1]
        local other = store[2]

        local n = select("#", ...)
        if n == 0 then return wrap(proxy[t](self, other)) end
        if n == 1 then return wrap(proxy[t](self, other, unwrap(...))) end
        return wrap(proxy[t](self, other, unwrap_args(n, ...)))
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Script


-- ========== Hooks ==========

-- BIND LIMITATIONS:
-- * If `method` is called by game code against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

gm.post_script_hook(gm.constants.function_dummy, function(self, other, result, args)
    -- Much faster than `gm.is_struct`
    local mt = getmetatable(self)
    if not mt then return end
    local name = mt.__name
    if  name ~= "sol.YYObjectBaseLuaWrapper"
    and name ~= "sol.CInstance*" then return end

    local fn = script_binded_functions[self.__id]
    if fn then
        local _args = args_holders[args_holder_rsp + 1]

        local n = #args
        for i = 1, n do
            local v = args_values[args_value_rsp + 1 + i]
            v.value = wrap(args[i].value)
            _args[i] = v
        end
        _args[n + 1] = nil

        args_holder_rsp = args_holder_rsp + 1
        args_value_rsp  = args_value_rsp  + 1 + n
        
        -- Call function with args
        -- and put return value into `result` (if applicable)
        local ret = fn(table_unpack(_args))
        if ret then
            result.value = unwrap(ret)
        end
    end
end)