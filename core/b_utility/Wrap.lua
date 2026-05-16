-- Wrap

---@class Wrap
Wrap = new_class()
C.Wrap = Wrap

local proxy = P.proxy


-- ========== Internal ==========

--[[
This is faster than iterative `select(i, ...)`, <br>
and *much* faster than `table.pack/unpack`.
]]
---@param n integer The number of args.
---@param ... any The varargs to unwrap.
---@return any ...
Wrap.internal.unwrap_args = function(n, ...) end

---@type function
local function unwrap_args(n, arg, ...)
    if n == 1 then return proxy[arg] or arg end
    return proxy[arg] or arg, unwrap_args(n - 1, ...)
end
Wrap.internal.unwrap_args = unwrap_args


-- ========== Static Methods ==========

--[[
Returns the unwrapped value of a RAPI wrapper, <br>
or `value` if it is not a wrapper.
]]
---@param value any The value to unwrap (if applicable).
---@return any
Wrap.unwrap = function(value)
    -- TODO For RAPI itself, inline this directly in build script(?)
    return proxy[value] or value
end

--[[
**[!] DEPRECATED**

Wraps the value with the appropriate RAPI wrapper (if applicable).
]]
---@deprecated
---@param value any The value to wrap.
---@return any
Wrap.wrap = function(value)
    return value
end


-- ========== Hooks ==========

-- Modify `__newindex` of `sol.RValue*` to do unwrapping on `v`
-- Can only obtain a `sol.RValue*` from a hook
if not P.ran_rvalue_modify then
    local hook1, hook2, hook3

    hook1 = gm.pre_script_hook(gm.constants.function_dummy, function(self, other, result, args)
        if P.ran_rvalue_modify then return end
        P.ran_rvalue_modify = true
        
        -- `sol.RValue*`
        local mt = getmetatable(args[1])
        local og_newindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            og_newindex(t, k, proxy[v] or v)
        end

        -- `sol.RValue`
        local mt = getmetatable(RValue.from_ptr(1))
        local og_newindex = mt.__newindex
        mt.__newindex = function(t, k, v)
            og_newindex(t, k, proxy[v] or v)
        end
    end)

    hook2 = gm.pre_code_execute("gml_Object_oInit_Step_0", function(self, other)
        if P.ran_rvalue_modify then return end
        gm.function_dummy(1)
    end)

    hook3 = gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
        gm.hook_disable(hook1)
        gm.hook_disable(hook2)
        gm.hook_disable(hook3)
    end)
end