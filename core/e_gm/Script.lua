-- Script

---@class Script
Script = {}
C.Script = Script

run_on_initial_load(function()
    P.script_binded_functions = {}  ---@type table<integer, function> Maps bind IDs to functions.
    P.script_binded_counter   = 0   -- Take before incrementing
    P.script_SO               = {}  ---@type table<Script, table> Stores `self`/`other` of Scripts. <br>`[1]` - `self` <br>`[2]` - `other`
end)

local script_binded_functions = P.script_binded_functions
local script_SO = P.script_SO

local select           = select
local getmetatable     = debug.getmetatable
local string_sub       = string.sub
local table_unpack     = table.unpack
local gm_call          = gm.call            ---@type function
local gm_method        = gm.method          ---@type function
local gm_struct_create = gm.struct_create   ---@type function
local unwrap           = Wrap.unwrap
local unwrap_args      = Wrap.internal.unwrap_args

local args_holders = {}     -- Reusable tables for arg holders
local args_holder_rsp = 0   -- Index of most recently used; increment before taking
for i = 1, 128 do args_holders[i] = {} end


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
    local scr = gm_method(struct, gm.constants.function_dummy)

    -- When called, the struct will be the `self` parameter
    -- Allows for the user to call the returned script
    scr.self  = struct
    scr.other = struct

    -- Store `fn`, which will be called
    -- when the binded `function_dummy` is called
    script_binded_functions[id] = fn
    P.script_binded_counter = id + 1

    return scr
end

--[[
**[!] DEPRECATED**

Returns a Script wrapper containing the provided script.
]]
---@deprecated
---@param script Script | sol.CScriptRef* The script to wrap.
---@return Script
Script.wrap = function(script)
    return script
end


-- ========== Metatables ==========

---@class Script
---@field RAPI string The name of this wrapper.
---@field name string The name of the script.
---@field script_name string Alias for `.name`.
---@field self sol.YYObjectBaseLuaWrapper | sol.CInstance* | nil The binded `self` that is passed in when called.
---@field other sol.YYObjectBaseLuaWrapper | sol.CInstance* | nil The binded `other` that is passed in when called.

local s = gm.struct_create()
local scr = gm.method(s, gm.constants.function_dummy)
local mt = getmetatable(scr)

run_on_initial_load(function()
    P.script_og_index = mt.__index  ---@type function
    P.script_og_call  = mt.__call   ---@type function
end)
local og_index = P.script_og_index
local og_call  = P.script_og_call

local mt_name = "Script"

W.Script = {
    __index = function(t, k)
        if k == "RAPI" then return mt_name end
        if k == "name" or k == "script_name" then
            return string_sub(og_index(t, "script_name"), 12, -1)
        end

        -- Get `self`/`other`
        if k == "self"
        or k == "other" then
            local so = script_SO[t]
            if not so then
                so = {}
                script_SO[t] = so
            end
            local index = (k == "self" and 1) or 2
            return so[index]
        end

        -- Call with manual `self`/`other`
        if k == "SO" then
            return function(self, other, ...)
                local n = select("#", ...)
                if n == 0 then return og_call(t, self, other) end
                if n == 1 then return og_call(t, self, other, unwrap(...)) end
                return og_call(t, self, other, unwrap_args(n, ...))
            end
        end
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "RAPI"
        or k == "name"
        or k == "script_name" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Set `self`/`other`
        if k == "self"
        or k == "other" then
            local index = (k == "self" and 1) or 2
            local cinstance = v -- May also be a Struct
            local so = script_SO[t]
            if not so then
                so = {}
                script_SO[t] = so
            end
            so[index] = cinstance
            return
        end

        log.error("Non-existent "..mt_name.." property '"..k.."'", 2)
    end,

    __call = function(t, ...)
        local store = script_SO[t]
        local self  = store[1]
        local other = store[2]

        local n = select("#", ...)
        if n == 0 then return og_call(t, self, other) end
        if n == 1 then return og_call(t, self, other, unwrap(...)) end
        return og_call(t, self, other, unwrap_args(n, ...))
    end,

    __tostring = function(t)
        return mt_name..": "..get_usertype_pointer(t)
    end,
}

table.merge(mt, W.Script)


-- ========== Hooks ==========

-- BIND LIMITATIONS:
-- * If `method` is called by game code against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

gm.post_script_hook(gm.constants.function_dummy, function(self, other, result, args)
    -- Much faster than `gm.is_struct`
    -- local mt = getmetatable(self)
    -- if not mt then return end
    -- local name = mt.__name
    -- if  name ~= "sol.YYObjectBaseLuaWrapper"
    -- and name ~= "sol.YYObjectBase*"
    -- and name ~= "sol.CInstance*" then return end

    if not self then return end

    local fn = script_binded_functions[self.__id]
    if fn then
        local _args = args_holders[args_holder_rsp + 1]
        args_holder_rsp = args_holder_rsp + 1

        local n = #args
        for i = 1, n do
            _args[i] = args[i].value
        end
        _args[n + 1] = nil

        -- Call function with args
        -- and put return value into `result` (if applicable)
        local ret = fn(table_unpack(_args))
        if ret then
            result.value = ret
        end

        args_holder_rsp = args_holder_rsp - 1
    end
end)