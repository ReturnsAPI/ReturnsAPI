-- Misc

---Functions to run after `core` has loaded.
---@type table<integer, function>
G.run_after_core = {}

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
Handles optional namespaces for method that have them.
]]
---@param namespace string | nil
---@param default_namespace string
---@return string namespace, boolean is_specified
function handle_optional_namespace(namespace, default_namespace)
    local is_specified = false
    if namespace then is_specified = true
    else namespace = default_namespace
    end
    return namespace, is_specified
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