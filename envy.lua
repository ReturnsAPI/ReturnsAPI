-- ENVY exports

local handle_optional_namespace = handle_optional_namespace

run_on_initial_load(function()
    --[[
    Stores import property tables (`@class ModData`). <br>
    Index key can be `guid` or `namespace`.
    ]]
    ---@type table<string, ModData>
    P.mod_data = {}

    ---@class ModData
    ---@field env table
    ---@field namespace string
    ---@field path string
    ---@field mp boolean Deprecated; is both `mp_local` and `mp_online`
    ---@field mp_local boolean
    ---@field mp_online boolean

    ---@type table<env, properties>
    P.auto_imports = {} -- Stores `_ENV`s of mods that call `.auto()`

    -- Store RAPI's own properties
    ---@type ModData
    local p = {
        env       = _ENV,
        mp_local  = true,
        mp_online = true,
        namespace = RAPI_NAMESPACE,
        path      = _ENV["!plugins_mod_folder_path"],
    }
    P.mod_data[_ENV["!guid"]]  = p
    P.mod_data[RAPI_NAMESPACE] = p
end)

--[[
Returns a table containing the API.

Properties:
- `env` - The `_ENV` table of your mod. <br>If not provided, automatically fetches your `_ENV`.
- `namespace` - The namespace by which your mod is identified for custom content, etc. <br>If not provided, defaults to your mod's name.
- `mp_local` - Set to `true` to mark your mod as safe to use in local multiplayer.
- `mp_online` - Set to `true` to mark your mod as safe to use in online multiplayer.
- `mp` - *Legacy - do not use*; acts as both `mp_local` and `mp_online`.
]]
---@param properties? table A table of import properties.
---@return table API
public.setup = function(properties)
    ---@type ModData
    properties = properties or {}
    properties.env  = properties.env or envy.getfenv(2)
    properties.path = properties.env["!plugins_mod_folder_path"]

    local guid = properties.env["!guid"]
    local namespace = properties.namespace

    -- Namespace validity check
    if namespace then
        namespace = tostring(namespace)
        if namespace:find("-") then log.error("setup: Namespace cannot contain a hyphen (-)", 2) end
    else
        namespace = guid:sub(guid:find("-") + 1, -1)
        log.warning("setup: No namespace provided by '"..guid.."'; defaulting to '"..namespace.."'")
    end

    -- Prevent taking a namespace already used internally
    if namespace == RAPI_NAMESPACE
    or namespace == "__permanent" then
        log.error("setup: Namespace '"..namespace.."' is reserved", 2)
    end

    -- Prevent taking a namespace already used by another mod
    local data = P.mod_data[namespace]
    if data then
        if guid ~= data.env["!guid"] then
            log.error("setup: Namespace '"..namespace.."' is already in use", 2)
        end
    end

    properties.namespace  = namespace
    P.mod_data[guid]      = properties
    P.mod_data[namespace] = properties

    local wrapper = {}

    -- For each public class, create a new table
    -- and copy all key-value pairs to it
    for name, class in pairs(C) do
        local copy = {}

        for k, v in pairs(class) do
            if k == "internal" then goto continue end

            -- Base copy
            copy[k] = v

            -- Namespace binding
            if type(v) == "function" then
                -- Immutable/implicit namespace
                -- (`NAMESPACE` (in caps) argument is first)
                if debug.getlocal(v, 1) == "NAMESPACE" then
                    copy[k] = function(...)
                        return v(namespace, ...)
                    end

                -- Optional namespace
                -- (`namespace` (not caps) argument)
                else
                    local pos = nil
                    local nparams = debug.getinfo(v).nparams
                    for i = 1, nparams do
                        if debug.getlocal(v, i):lower() == "namespace" then
                            pos = i
                            break
                        end
                    end
                    if not pos then goto continue end

                    -- Handled like this to minimize function calls (i.e., `table.pack/unpack`)
                    -- `ns or namespace` - Use default namespace if not provided
                    -- `ns and true`     - `true` if a namespace was provided
                    if pos == 1 then
                        copy[k] = function(ns)
                            return v(ns or namespace, ns and true)
                        end
                    elseif pos == 2 then
                        copy[k] = function(arg1, ns)
                            return v(arg1, ns or namespace, ns and true)
                        end
                    elseif pos == 3 then
                        copy[k] = function(arg1, arg2, ns)
                            return v(arg1, arg2, ns or namespace, ns and true)
                        end
                    elseif pos == 4 then
                        copy[k] = function(arg1, arg2, arg3, ns)
                            return v(arg1, arg2, arg3, ns or namespace, ns and true)
                        end
                    elseif pos == 5 then
                        copy[k] = function(arg1, arg2, arg3, arg4, ns)
                            return v(arg1, arg2, arg3, arg4, ns or namespace, ns and true)
                        end
                    elseif pos == 6 then
                        copy[k] = function(arg1, arg2, arg3, arg4, arg5, ns)
                            return v(arg1, arg2, arg3, arg4, arg5, ns or namespace, ns and true)
                        end
                    elseif pos == 7 then
                        copy[k] = function(arg1, arg2, arg3, arg4, arg5, arg6, ns)
                            return v(arg1, arg2, arg3, arg4, arg5, arg6, ns or namespace, ns and true)
                        end
                    end
                end

            -- Tables
            elseif type(v) == "table" and not v.RAPI then
                -- Copy pairs to new table
                local t = {}
                for k2, v2 in pairs(v) do
                    t[k2] = v2
                end
                copy[k] = t
            end

            ::continue::
        end

        -- Copy over class metatable (if applicable)
        if M[name] then setmetatable(copy, M[name]) end

        wrapper[name] = copy
    end

    -- Run import functions
    if P.run_on_import then
        for _, fn in ipairs(P.run_on_import) do
            fn(namespace)
        end
    end

    return wrapper
end

--[[
Imports the API directly into your environment.

Properties:
- `env` - The `_ENV` table of your mod. <br>If not provided, automatically fetches your `_ENV`.
- `namespace` - The namespace by which your mod is identified for custom content, etc. <br>If not provided, defaults to your mod's name.
- `mp_local` - Set to `true` to mark your mod as safe to use in local multiplayer.
- `mp_online` - Set to `true` to mark your mod as safe to use in online multiplayer.
- `mp` - *Legacy - do not use*; acts as both `mp_local` and `mp_online`.
]]
---@param properties? table A table of import properties.
public.auto = function(properties)
    ---@type ModData
    properties = properties or {}
    properties.env = properties.env or envy.getfenv(2)
    local env = properties.env

    local wrapper = public.setup(properties)
    envy.import_all(env, wrapper)

    P.auto_imports[env] = properties

    -- Add extensions directly to Lua's tables
    for k, v in pairs(Math)   do env.math[k]   = v end
    for k, v in pairs(String) do env.string[k] = v end
    for k, v in pairs(Table)  do env.table[k]  = v end

    -- Override default `type`
    if not env.lua_print then
        env.lua_type = env.type
    end
    env.type = wrapper.Util.type
end

-- NOTE: Do service subscriptions for `setup()` too,
-- but not anything that imports directly into env
    -- Subscriptions:
    -- * Language autoregister
    -- * MP check
    -- ✓ Remove callback functions on hotload