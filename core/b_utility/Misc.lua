-- Misc

local debug_getinfo = debug.getinfo
local log_error     = log.error

---Functions to run after `core` has loaded.
---@type table<integer, function>
G.run_after_core = {}

---Functions to run during content initialization.
---@type table<integer, function>
G.run_on_initialize = {}

--[[
Returns a table with a subtable called `internal`.

Methods in `internal` will *not* be exported to users, <br>
and are meant for internal use within RAPI.
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
Runs a function during the content initialization loop, <br>
before all other mods' functions.
]]
function run_on_initialize(fn)
    table.insert(G.run_on_initialize, fn)
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

--[[
Expands `~` to mod folder path.
]]
---@param namespace string
---@param path string
---@return string expanded_path
function expand_path(namespace, path)
    local expansion = P.mod_data[namespace].path.."/"
    return path:gsub("~", expansion)
end

--[[
Variant of `log.error` for use in methods. <br>
Automatically prepends the method name and uses correct level of error.
]]
function throw(msg)
    local name = debug_getinfo(2, "n").name
    log_error(name..": "..msg, 3)

    -- TODO blame might need to go +1 level for ns-binded closures?
end