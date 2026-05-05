-- Misc

local debug_getinfo = debug.getinfo
local log_error     = log.error
local unwrap  -- Set after core load (under `unwrap_args` below)

---Functions to run after `core` has loaded.
---@type table<integer, function>
G.run_after_core = {}

---Functions to run during content initialization.
---@type table<integer, function>
G.run_on_initialize = {}

---Functions to run when RAPI is imported. <br>
---This is in `P` so that RAPI can <br>
---run it for itself on hotload.
---@type table<integer, function>
P.run_on_import = {}

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
Runs a function for a mod when it imports RAPI, <br>
including when it hotloads.

The function will be passed the mod's namespace.
]]
---@param fn function The function to run.
function run_on_import(fn)
    table.insert(P.run_on_import, fn)
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
---@param msg string The message to display.
---@param name string? The name of the method. <br>Necessary for namespace-binded methods.
function throw(msg, name)
    local n = name or debug_getinfo(2, "n").name
    log_error(tostring(n)..": "..msg, 3)
end

--[[
This is faster than iterative `select(i, ...)`, <br>
and *much* faster than `table.pack/unpack`.
]]
---@param n integer The number of args.
---@param ... any The varargs to unwrap.
---@return any ...
function unwrap_args(n, ...) end
function unwrap_args(n, arg, ...)
    if n == 1 then return unwrap(arg) end
    return unwrap(arg), unwrap_args(n - 1, ...)
end
run_after_core(function() unwrap = Wrap.unwrap end)