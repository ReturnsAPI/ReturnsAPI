-- GM

GM = {}

local function_cache = {}



-- ========== Metatables ==========

metatable_GM = {
    __index = function(t, k)
        if not gmf[k] then log.error("GM."..k.." does not exist", 2) end
        if not function_cache[k] then
            function_cache[k] = function(...)
                local count = select("#", ...)
                local args = {...}
                if #args ~= count then log.error("Argument mismatch; should be "..count, 2) end
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
        end
        return function_cache[k]
    end,


    __newindex = function(t, k, v)
        log.error("GM has nothing to set", 2)
    end,


    __metatable = "RAPI.Class.GM"
}
setmetatable(GM, metatable_GM)



_CLASS["GM"] = GM
_CLASS_MT["GM"] = metatable_GM