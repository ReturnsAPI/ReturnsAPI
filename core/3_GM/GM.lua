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



-- ========== Methods ==========

-- For builtin functions, `gm` (sol) is faster
-- For script functions, `gmf` (RValue) is faster

local call = function(k)
    if not __GM_function_cache[k] then
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end

        if GM.internal.builtin[k] then
            __GM_function_cache[k] = function(...)
                local args = table.pack(...)

                -- Unwrap args
                for i = 1, args.n do
                    args[i] = Wrap.unwrap(args[i])
                end

                return Wrap.wrap(gm[k](table.unpack(args)))
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
                local args = table.pack(...)

                -- Unwrap args
                for i = 1, args.n do
                    args[i] = Wrap.unwrap(args[i])
                end

                return Wrap.wrap(gm.call(k, self.CInstance, other.CInstance, table.unpack(args)))
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



-- ========== Populate function cache with common ones ==========

local fns = {

    -- === variable_global ===

    variable_global_get = function(name)
        return Wrap.wrap(gm.variable_global_get(name))
    end,

    variable_global_set = function(name, value)
        gm.variable_global_set(name, Wrap.unwrap(value, true))
    end,


    -- === instance ===
    
    instance_find = function(object, index)
        return Instance.wrap(gm.instance_find(Wrap.unwrap(object), index))
    end,

    instance_exists = function(inst)
        return (gm.instance_exists(Wrap.unwrap(inst)) == 1)
    end,

    instance_create = function(x, y, object)
        return Instance.wrap(gm.instance_create(Wrap.unwrap(x), Wrap.unwrap(y), Wrap.unwrap(object)))
    end,

    instance_destroy = function(inst)
        gm.instance_destroy(Wrap.unwrap(inst))
    end,

    instance_number = function(object)
        return gm.instance_number(Wrap.unwrap(object))
    end,

}

for k, v in pairs(fns) do
    __GM_function_cache[k] = v
end



-- ========== Notable Functions ==========

--@section Notable Functions

--[[
**Actors**
Function | Arguments | Description
| - | - | -
`actor_heal_barrier( actor, amount )` | `actor` - The actor to grant to. <br>`amount` - The amount of barrier to grant. | Grants barrier to the actor. <br>Automatically capped by the actor's `maxbarrier`.
]]