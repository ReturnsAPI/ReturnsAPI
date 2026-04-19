-- GM

--[[
Variant of `gm` that works with RAPI's wrappers.
]]
---@class GM
GM = new_class()
C.GM = GM

--[[
Variant of `GM` that accepts `self` and `other`. <br>
*Technical:* Uses `gm.call` (slower than `gm`).
]]
---@class GM.SO
GM.SO = new_class()
C.GM_SO = GM.SO

local type    = type
local rawget  = rawget
local select  = select
local gm      = gm
local gm_call = gm.call
local wrap    = Wrap.wrap
local unwrap  = Wrap.unwrap


-- ========== Static Methods ==========

-- This is faster than iterative `select(i, ...)`, <br>
-- and *much* faster than `table.pack/unpack`
local function unwrap_args(n, arg, ...)
    if n == 0 then return end
    return unwrap(arg), unwrap_args(n - 1, ...)
end

-- Loop through constants and add all scripts to GM
for name, _ in pairs(gm.constants) do
    local _type = gm.constant_types[name]
    if _type == "script"
    or _type == "gml_script" then

        -- Normal
        local fn = gm[name]
        GM[name] = function(...)
            local n = select("#", ...)
            if n == 0 then return wrap(fn()) end
            if n == 1 then return wrap(fn(unwrap(select(1, ...)))) end
            return wrap(fn(unwrap_args(n, ...)))   -- TODO need to verify if this works the same as before over gm.call
        end

        -- self/other
        GM.SO[name] = function(self, other, ...)
            local n = select("#", ...)
            if n == 0 then return wrap(gm_call(name, unwrap(self), unwrap(other))) end
            if n == 1 then return wrap(gm_call(name, unwrap(self), unwrap(other), unwrap(select(1, ...)))) end
            return wrap(gm_call(name, unwrap(self), unwrap(other), unwrap_args(n, ...)))
        end

    end
end


-- ========== Metatables ==========

---@class GM
---@field SO GM.SO

M.GM = {
    __index = function(t, k)
        return rawget(t, k)
    end,
    
    __newindex = function(t, k, v)
        log.error("GM has no properties to set", 2)
    end,

    __metatable = mt_class_name("GM"),
}
setmetatable(GM, M.GM)

M.GM_SO = {
    __index = function(t, k)
        return rawget(t, k)
    end,
    
    __newindex = function(t, k, v)
        log.error("GM.SO has no properties to set", 2)
    end,

    __metatable = mt_class_name("GM.SO"),
}
setmetatable(GM.SO, M.GM_SO)