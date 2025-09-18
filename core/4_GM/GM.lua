-- GM

--[[
This class is a version of `gm` that automatically
wraps/unwraps values with ReturnsAPI wrappers.

E.g.,
```lua
GM.instance_create(x, y, Object.find("lizard"))    --> returns an Actor wrapper
```

If you need to pass a struct/instance into `self`/`other`, use `GM.SO`.

E.g.,
```lua
-- The first two arguments are `self, other`
GM.SO.recalculate_stats(actor, actor)
```

**Note**
If you do *not* need automatic wrapping/unwrapping, it may be faster to just use `gm`.

E.g.,
```lua
gm.object_get_name(gm.constants.oP)

-- is marginally faster than

GM.object_get_name(gm.constants.oP)
```
]]

GM = new_class()
GM_callso = new_class()



-- ========== Functions ==========

-- Loop through constants and
-- add all scripts to GM
for fn, _ in pairs(gm.constants) do
    local type_ = gm.constant_types[fn]
    if type_ == "script" or type_ == "gml_script" then

        -- Normal
        GM[fn] = function(...)
            local args = table.pack(...)

            -- Unwrap args
            for i = 1, args.n do
                args[i] = Wrap.unwrap(args[i])
            end

            return Wrap.wrap(gm.call(fn, nil, nil, table.unpack(args)))
        end

        -- self/other
        GM_callso[fn] = function(self, other, ...)
            local args = table.pack(...)

            -- Unwrap args
            for i = 1, args.n do
                args[i] = Wrap.unwrap(args[i])
            end

            return Wrap.wrap(gm.call(fn, Wrap.unwrap(self, true), Wrap.unwrap(other, true), table.unpack(args)))
        end

    end
end



-- ========== Metatables ==========

make_table_once("metatable_GM", {
    __index = function(t, k)
        if k == "SO" then return GM_callso end
        return t[k]
    end,


    __newindex = function(t, k, v)
        log.error("GM has no properties to set", 2)
    end,


    __metatable = "RAPI.Class.GM"
})
setmetatable(GM, metatable_GM)


make_table_once("metatable_callso", {
    __index = function(t, k)
        return t[k]
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