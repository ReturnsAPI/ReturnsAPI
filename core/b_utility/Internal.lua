-- Misc

---@type table<integer, function>
G.run_after_core = {}

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
Runs a function after `core` has loaded.
]]
---@param fn function The function to run.
function run_after_core(fn)
    table.insert(G.run_after_core, fn)
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