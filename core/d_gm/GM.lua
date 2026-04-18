-- GM

--[[
Variant of `gm` that works with RAPI's wrappers.
]]
---@class GM
GM = new_class()
C.GM = GM

--[[
Variant of `GM` that accepts `self` and `other`.
]]
---@class GM.SO
GM.SO = new_class()
C.GM_SO = GM.SO

local type         = type
local rawget       = rawget
local table_pack   = table.pack
local table_unpack = table.unpack
local gm           = gm
local gm_call      = gm.call
local wrap         = Wrap.wrap
local unwrap       = Wrap.unwrap


-- ========== Static Methods ==========

-- Loop through constants and add all scripts to GM
for name, _ in pairs(gm.constants) do
    local _type = gm.constant_types[name]
    if _type == "script"
    or _type == "gml_script" then

        -- Normal
        GM[name] = function(...)
            local args = table_pack(...)
            for i = 1, args.n do
                args[i] = unwrap(args[i])
            end
            return wrap(gm[name](table_unpack(args))) -- TODO need to verify if this works over gm.call
        end

        -- self/other
        GM.SO[name] = function(self, other, ...)
            local args = table_pack(...)
            for i = 1, args.n do
                args[i] = unwrap(args[i])
            end
            return wrap(gm_call(name, unwrap(self), unwrap(other), table_unpack(args)))
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