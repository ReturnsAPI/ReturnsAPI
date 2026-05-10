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

local type        = type
local rawget      = rawget
local select      = select
local gm          = gm
local gm_call     = gm.call
local wrap        = Wrap.wrap
local unwrap      = Wrap.unwrap
local unwrap_args = unwrap_args


-- ========== Static Methods ==========

-- Loop through constants and add all scripts to GM
for name, _ in pairs(gm.constants) do
    local _type = gm.constant_types[name]
    if _type == "script"
    or _type == "gml_script" then

        -- Normal
        local fn = gm[name]
        GM[name] = function(...)
            local n = select("#", ...)
            if n == 0 then return fn() end
            if n == 1 then return fn(unwrap(...)) end
            return fn(unwrap_args(n, ...))  -- TODO need to verify if this works the same as before over gm.call
        end

        -- self/other
        GM.SO[name] = function(self, other, ...)
            local n = select("#", ...)
            if n == 0 then return gm_call(name, self, other) end
            if n == 1 then return gm_call(name, self, other, unwrap(...)) end
            return gm_call(name, self, other, unwrap_args(n, ...))
        end

    end
end


-- ========== Metatables ==========

---@class GM
---@field SO GM.SO
---@field [string] function

M.GM = {
    __newindex = function(t, k, v)
        log.error("GM has no properties to set", 2)
    end,

    __metatable = mt_class_name("GM"),
}
setmetatable(GM, M.GM)

---@class GM.SO
---@field [string] function

M.GM_SO = {
    __newindex = function(t, k, v)
        log.error("GM.SO has no properties to set", 2)
    end,

    __metatable = mt_class_name("GM.SO"),
}
setmetatable(GM.SO, M.GM_SO)