-- Misc

--[[
Returns a `__metatable` string for classes.
]]
---@param name string
---@return string
function mt_class_name(name)
    return "RAPI.Class."..name
end

--[[
Returns a `__metatable` string for wrappers.
]]
---@param name string
---@return string
function mt_wrapper_name(name)
    return "RAPI.Wrapper."..name
end