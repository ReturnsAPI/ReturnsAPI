-- Misc

---Functions to run after `core` has loaded.
---@type table<integer, function>
G.run_after_core = {}

--[[
Returns a table with a subtable called `internal`.

Methods in `internal` will *not* be exported to users, <br>
and are meant for internal use within ReturnsAPI.
]]
---@return table
function new_class()
    return {
        internal = {}
    }
end

--[[
Runs a function only on initial load, and never on hotload.
]]
---@param fn function The function to run.
function run_on_initial_load(fn)
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