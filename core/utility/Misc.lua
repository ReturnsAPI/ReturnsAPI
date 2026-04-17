-- Misc

--[[
Runs a function only on initial load, and never on hotload.
]]
---@param fn function The function to run.
function run_once(fn)
    if not P.hotload then
        fn()
    end
end

--[[
Runs a function only on hotload.
]]
---@param fn function The function to run.
function run_on_hotload(fn)
    if P.hotload then
        fn()
    end
end

--[[
Returns a table meant for storing other tables. <br>
These stored tables will only be created once, <br>
and further setting will update the existing one.

This is used to allow ReturnsAPI to be hotloaded and <br>
automatically update metatables of existing wrappers.
]]
---@return table
function make_table_once()
    local _t = {}
    return setmetatable({}, {
        __index = function(t, k)
            return _t[k]
        end,

        __newindex = function(t, k, v)
            if _t[k] then
                table.merge(_t[k], v)
                return
            end
            _t[k] = v
        end,
    })
end

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