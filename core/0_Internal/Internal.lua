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
    if not hotloaded then fn() end
end


-- Runs the function only on hotload
function run_on_hotload(fn)
    if hotloaded then fn() end
end


-- Create a new table once
-- On hotload, merge new changes into it
function make_table_once(table_name, merge)
    -- Create new table in this mod's globals if it existn't
    -- (Accessed via `private` -- construct from ENVY)
    if not private[table_name] then private[table_name] = {} end

    -- Merge table on hotload; update with new changes
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



-- ========== FFI ==========

run_once(function()
    -- jit.off ffi calls
    FFI = {
        cast    = function(...) return ffi.cast(...)    end,
        new     = function(...) return ffi.new(...)     end,
        typeof  = function(...) return ffi.typeof(...)  end,
        load    = function(...) return ffi.load(...)    end,
        cdef    = function(...) return ffi.cdef(...)    end,
        string  = function(...) return ffi.string(...)  end
    }
    for _, fn in pairs(FFI) do
        jit.off(fn)
    end

    -- Public export
    __class.FFI = FFI
end)



-- ========== Proxy ==========

run_once(function()
    __proxy = setmetatable({}, {__mode = "k"})

    local proxy_default_name = "Proxy"
    local proxy_default_mt  = { __index = function(t, k)
                                    if k == "RAPI" then return proxy_default_name end
                                    return __proxy[t][k]
                                end,
                                __newindex = function(t, k, v) __proxy[t][k] = v end,
                                __metatable = "RAPI.Wrapper."..proxy_default_name }

    function make_proxy(t, mt)
        -- Returns a new proxy table, which is used as
        -- a "key" to access the real table/data in storage.
        local proxy = {}
        __proxy[proxy] = t or {}
        Util.setmetatable_gc(proxy, mt or proxy_default_mt)
        return proxy
    end
end)