-- GM

GM = new_class()

local function_cache = {}
local function_cache_callso = {}



-- ========== Lookup Tables ==========

GM.internal.builtin = require("./core/data/gmfBuiltin.lua")
GM.internal.object  = require("./core/data/gmfObject.lua")
GM.internal.script  = require("./core/data/gmfScript.lua")



-- ========== Methods ==========

methods_GM = {

    call = function(k)
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end
        if not function_cache[k] then

            if GM.internal.builtin[k] then
                function_cache[k] = function(...)
                    local args = table.pack(...)

                    -- Convert args to sol where applicable
                    for i = 1, args.n do
                        args[i] = Wrap.unwrap_to_sol(args[i])
                    end

                    return RValue.sol_to_wrapper(gm.call(k, nil, nil, table.unpack(args)))
                end

            elseif GM.internal.object[k] then
                function_cache[k] = function()
                    gmf[k](nil, nil)
                end

            elseif GM.internal.script[k] then
                function_cache[k] = function(...)
                    local args = table.pack(...)
                    local holder = RValue.new_holder_scr(args.n)

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
        return function_cache[k]
    end,


    callso = function(k)
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end
        if not function_cache_callso[k] then

            if GM.internal.builtin[k] then
                function_cache_callso[k] = function(self, other, ...)
                    local args = table.pack(...)

                    -- Convert args to sol where applicable
                    for i = 1, args.n do
                        args[i] = Wrap.unwrap_to_sol(args[i])
                    end

                    return RValue.sol_to_wrapper(gm.call(k, Wrap.unwrap_to_sol(self), Wrap.unwrap_to_sol(other), table.unpack(args)))
                end

            elseif GM.internal.object[k] then
                function_cache_callso[k] = function(self, other)
                    gmf[k](self.CInstance, other.CInstance)
                end

            elseif GM.internal.script[k] then
                function_cache_callso[k] = function(self, other, ...)
                    local args = table.pack(...)
                    local holder = RValue.new_holder_scr(args.n)

                    -- Populate holder
                    for i = 1, args.n do
                        holder[i - 1] = RValue.from_wrapper(args[i])
                    end

                    local out = RValue.new(0)
                    gmf[k](self.CInstance, other.CInstance, out, args.n, holder)
                    return RValue.to_wrapper(out)
                end

            end
        end
        return function_cache_callso[k]
    end

}



-- ========== Metatables ==========

metatable_GM = {
    __index = function(t, k)
        if k == "SO" then return callso end
        return methods_GM.call(k)
    end,


    __newindex = function(t, k, v)
        log.error("GM has nothing to set", 2)
    end,


    __metatable = "RAPI.Class.GM"
}
setmetatable(GM, metatable_GM)


metatable_callso = {
    __index = function(t, k)
        return methods_GM.callso(k)
    end,


    __newindex = function(t, k, v)
        log.error("GM.SO has nothing to set", 2)
    end,


    __metatable = "RAPI.Class.GM.SO"
}
callso = setmetatable({}, metatable_callso)



__class.GM = GM
__class_mt.GM = metatable_GM