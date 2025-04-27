-- GM

--[[
This class is a version of `gm` that automatically
wraps/unwraps values with ReturnsAPI wrappers.

E.g.,
```lua
GM.instance_create(x, y, Object.find("lizard"))
```

If you need to pass a struct/instance into `self`/`other`, use `GM.SO`.

E.g.,
```lua
-- The first two arguments are `self, other`
GM.SO.recalculate_stats(actor, actor)
```
]]

GM = new_class()
GM_callso = new_class()

run_once(function()
    __GM_function_cache = {}
    __GM_function_cache_callso = {}
end)



-- ========== Lookup Tables ==========

GM.internal.builtin = require("./core/data/gmfBuiltin.lua")
GM.internal.object  = require("./core/data/gmfObject.lua")
GM.internal.script  = require("./core/data/gmfScript.lua")

GM.internal.builtin_globals = {}
for i = 0, gm.gmf_builtin_variables_count() - 1 do
    local builtin_var = gmf.__builtin_variables[i]
    if builtin_var.name then
        local str = ffi.string(builtin_var.name)
        GM.internal.builtin_globals[str] = builtin_var
    end
end


-- TODO uh maybe figure out a fix so these don't have to be jit.offed?
for k, v in pairs(GM.internal.object) do
    jit.off(gmf[k])
end

for k, v in pairs(GM.internal.script) do
    jit.off(gmf[k])
end



-- ========== Methods ==========

local call = function(k)
    if not __GM_function_cache[k] then
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end

        if k == "variable_global_get" then
            __GM_function_cache[k] = function(name)
                -- Built-in globals
                local builtin_var = GM.internal.builtin_globals[name]
                if builtin_var then
                    local out = RValue.new(0)
                    builtin_var.getter(nil, nil, out)
                    return RValue.to_wrapper(out)
                end

                -- Game-defined globals
                local holder = RValue.new_holder(1)
                holder[0] = RValue.new(name)
                local out = RValue.new(0)
                gmf.variable_global_get(out, nil, nil, 1, holder)
                return RValue.to_wrapper(out)
            end

        elseif k == "variable_global_set" then
            __GM_function_cache[k] = function(name, value)
                -- Built-in globals
                local builtin_var = GM.internal.builtin_globals[name]
                if builtin_var then
                    local val = RValue.from_wrapper(value)
                    builtin_var.setter(nil, nil, val)
                end

                -- Game-defined globals
                local holder = RValue.new_holder(2)
                holder[0] = RValue.new(name)
                holder[1] = RValue.from_wrapper(value)
                gmf.variable_global_set(RValue.new(0), nil, nil, 2, holder)
            end

        elseif GM.internal.builtin[k] then
            __GM_function_cache[k] = function(...)
                local args = table.pack(...)
                local holder = nil
                if args.n > 0 then holder = RValue.new_holder(args.n) end

                -- Populate holder
                for i = 1, args.n do
                    holder[i - 1] = RValue.from_wrapper(args[i])
                end

                local out = RValue.new(0)
                gmf[k](out, nil, nil, args.n, holder)
                return RValue.to_wrapper(out)
            end

        elseif GM.internal.object[k] then
            __GM_function_cache[k] = function()
                gmf[k](nil, nil)
            end

        elseif GM.internal.script[k] then
            __GM_function_cache[k] = function(...)
                local args = table.pack(...)
                local holder = nil
                if args.n > 0 then holder = RValue.new_holder_scr(args.n) end

                -- Populate holder
                for i = 1, args.n do
                    holder[i - 1] = RValue.from_wrapper(args[i])
                end

                local out = RValue.new(0)
                gmf[k](nil, nil, out, args.n, holder)
                return RValue.to_wrapper(out)
            end

        end
    end
    return __GM_function_cache[k]
end


local callso = function(k)
    if not __GM_function_cache_callso[k] then
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end

        if GM.internal.builtin[k] then
            __GM_function_cache_callso[k] = function(self, other, ...)
                if self then self = self.CInstance end
                if other then other = other.CInstance end
                
                local args = table.pack(...)
                local holder = nil
                if args.n > 0 then holder = RValue.new_holder(args.n) end

                -- Populate holder
                for i = 1, args.n do
                    holder[i - 1] = RValue.from_wrapper(args[i])
                end

                local out = RValue.new(0)
                gmf[k](out, self, other, args.n, holder)
                return RValue.to_wrapper(out)
            end

        elseif GM.internal.object[k] then
            __GM_function_cache_callso[k] = function(self, other)
                if self then self = self.CInstance end
                if other then other = other.CInstance end

                gmf[k](self, other)
            end

        elseif GM.internal.script[k] then
            __GM_function_cache_callso[k] = function(self, other, ...)
                if self then self = self.CInstance end
                if other then other = other.CInstance end

                local args = table.pack(...)
                local holder = nil
                if args.n > 0 then holder = RValue.new_holder_scr(args.n) end

                -- Populate holder
                for i = 1, args.n do
                    holder[i - 1] = RValue.from_wrapper(args[i])
                end

                local out = RValue.new(0)
                gmf[k](self, other, out, args.n, holder)
                return RValue.to_wrapper(out)
            end

        end
    end
    return __GM_function_cache_callso[k]
end



-- ========== Metatables ==========

make_table_once("metatable_GM", {
    __index = function(t, k)
        if k == "SO" then return GM_callso end
        return call(k)
    end,


    __newindex = function(t, k, v)
        log.error("GM has no properties to set", 2)
    end,


    __metatable = "RAPI.Class.GM"
})
setmetatable(GM, metatable_GM)


make_table_once("metatable_callso", {
    __index = function(t, k)
        return callso(k)
    end,


    __newindex = function(t, k, v)
        log.error("GM.SO has no properties to set", 2)
    end,


    __metatable = "RAPI.Class.GM.SO"
})
setmetatable(GM_callso, metatable_callso)



-- Public export
__class.GM = GM
__class_mt.GM = metatable_GM



-- ========== Notable Functions ==========

--@section Notable Functions

--[[
**Actors**
Function | Arguments | Description
| - | - | -
`actor_heal_barrier( actor, amount )` | `actor` - The actor to grant to. <br>`amount` - The amount of barrier to grant. | Grants barrier to the actor. <br>Automatically capped by the actor's `maxbarrier`.
]]