-- GM

GM = {}

local function_cache = {}
local function_cache_callso = {}



-- ========== Lookup Tables ==========

gmf_builtin = require("./core/data/gmfBuiltin")
gmf_object = require("./core/data/gmfObject")
gmf_script = require("./core/data/gmfScript")



-- ========== Methods ==========

methods_GM = {

    call = function(k)
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end
        if not function_cache[k] then

            if gmf_builtin[k] then
                function_cache[k] = function(...)
                    -- local count = select("#", ...)
                    local args = {...}
                    local count = #args
                    -- if #args ~= count then log.error("Argument mismatch; should be "..count, 2) end
                    local holder = ffi.new("struct RValue["..count.."]")

                    -- Populate holder
                    for i = 1, count do
                        holder[i - 1] = RValue.new(Wrap.unwrap(args[i]))
                        -- print("holder "..(i-1)..": "..tostring(holder[i - 1]))
                    end

                    local out = RValue.new(0)
                    gmf[k](out, nil, nil, count, holder)
                    return RValue.to_wrapper(out)
                end

            elseif gmf_object[k] then
                function_cache[k] = function()
                    gmf[k](nil, nil)
                end

            elseif gmf_script[k] then
                function_cache[k] = function(...)
                    -- local count = select("#", ...)
                    local args = {...}
                    local count = #args
                    -- if #args ~= count then log.error("Argument mismatch; should be "..count, 2) end
                    local holder = ffi.new("struct RValue*["..count.."]")

                    -- Populate holder
                    for i = 1, count do
                        holder[i - 1] = RValue.new(Wrap.unwrap(args[i]))
                        -- print("holder "..(i-1)..": "..tostring(holder[i - 1]))
                    end

                    local out = RValue.new(0)
                    gmf[k](nil, nil, out, count, holder)
                    return RValue.to_wrapper(out)
                end

            end
        end
        return function_cache[k]
    end,


    callso = function(k)
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end
        if not function_cache_callso[k] then

            if gmf_builtin[k] then
                function_cache_callso[k] = function(self, other, ...)
                    -- local count = select("#", ...)
                    local args = {...}
                    local count = #args
                    -- if #args ~= count then log.error("Argument mismatch; should be "..count, 2) end
                    local holder = ffi.new("struct RValue["..count.."]")

                    -- Populate holder
                    for i = 1, count do
                        holder[i - 1] = RValue.new(Wrap.unwrap(args[i]))
                        -- print("holder "..(i-1)..": "..tostring(holder[i - 1]))
                    end

                    local out = RValue.new(0)
                    gmf[k]( out,
                            gm.CInstance.instance_id_to_CInstance[Wrap.unwrap(self)],
                            gm.CInstance.instance_id_to_CInstance[Wrap.unwrap(other)],
                            count,
                            holder)
                    return RValue.to_wrapper(out)
                end

            elseif gmf_object[k] then
                function_cache_callso[k] = function(self, other)
                    gmf[k]( gm.CInstance.instance_id_to_CInstance[Wrap.unwrap(self)],
                            gm.CInstance.instance_id_to_CInstance[Wrap.unwrap(other)])
                end

            elseif gmf_script[k] then
                function_cache_callso[k] = function(self, other, ...)
                    -- local count = select("#", ...)
                    local args = {...}
                    local count = #args
                    -- if #args ~= count then log.error("Argument mismatch; should be "..count, 2) end
                    local holder = ffi.new("struct RValue*["..count.."]")

                    -- Populate holder
                    for i = 1, count do
                        holder[i - 1] = RValue.new(Wrap.unwrap(args[i]))
                        -- print("holder "..(i-1)..": "..tostring(holder[i - 1]))
                    end

                    local out = RValue.new(0)
                    gmf[k]( gm.CInstance.instance_id_to_CInstance[Wrap.unwrap(self.value)],
                            gm.CInstance.instance_id_to_CInstance[Wrap.unwrap(other)],
                            out,
                            count,
                            holder)
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
        if k == "callso" then return callso end
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
        log.error("GM.callso has nothing to set", 2)
    end,


    __metatable = "RAPI.Class.GM.callso"
}
callso = setmetatable({}, metatable_callso)



_CLASS["GM"] = GM
_CLASS_MT["GM"] = metatable_GM