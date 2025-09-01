-- Internal

-- Returns a table with a subtable called `internal`
-- Methods in `internal` will *not* be exported to users,
-- and are meant for internal use within RAPI
function new_class()
    return {
        internal = {}
    }
end


-- Runs the function only once on initial load,
-- and never again on hotload
function run_once(fn)
    if not hotloaded then
        fn()
    end
end


-- Runs the function only on hotload
function run_on_hotload(fn)
    if hotloaded then
        fn()
    end
end


-- Runs the function after core has been loaded
_run_after_core = {}
function run_after_core(fn)
    table.insert(_run_after_core, fn)
end


-- Create a new table once
-- On hotload, merge new changes into it if specified
function make_table_once(table_name, merge)
    -- Create new table in this mod's globals if it existn't
    -- (Accessed via `private` -- construct from ENVY)
    if not private[table_name] then private[table_name] = {} end

    -- Merge table on hotload if specified (i.e., update with new changes)
    if merge then
        local t = private[table_name]
        for k, v in pairs(merge) do
            t[k] = v
        end
    end
end


-- Returns the namespace to use, and `true`
-- if the user actually provided an optional name
function parse_optional_namespace(namespace, default_namespace)
    local is_specified = false
    if namespace then
        if namespace == "~" then namespace = default_namespace end
        is_specified = true
    else namespace = default_namespace
    end
    return namespace, is_specified
end



-- ========== Public Export ==========

run_once(function()
    __class     = {}    -- Every public class
    __class_mt  = {}    -- Metatable for public class (optional, should be the same key as in __class)
end)

-- __ref_map created in Map.lua