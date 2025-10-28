-- Hook

--[[
Allows for calling a function before/after a game function.

**Script hook callback arguments**
Argument | Type | Description
| - | - | -
`self`      | Instance, Struct, or nil  | The calling instance.
`other`     | Instance, Struct, or nil  | The "other" instance.
`result`    |                           | The post-hook return value (`nil` for pre-hooks). <br>Get/set using `result.value`. <br>Can only be set in post-hooks.
`args`      | table                     | The called game function's arguments. <br>Get/set using `args[i].value`. <br>Can only be set in pre-hooks.

**Object hook callback arguments**
Argument | Type | Description
| - | - | -
`self`      | Instance, Struct, or nil  | The calling instance.
`other`     | Instance, Struct, or nil  | The "other" instance.

In a pre-hook, returning `false` will prevent normal execution of the game function (post-hooks will still run).
]]

Hook = new_class()

run_once(function()
    __pre_hooks         = {}
    __post_hooks        = {}
    __pre_hook_cache    = CallbackCache.new()
    __post_hook_cache   = CallbackCache.new()
    __hook_current_id   = -1    -- Shared by both __pre and __post
end)

local banned_scripts = {
    gm.constants.step_actor,    -- Bad for performance
    gm.constants.draw_actor,    -- Bad for performance
}



-- ========== Internal ==========

Hook.internal.manage_pre_hook = function(script)
    -- Enable/disable existing hook based on
    -- whether or not there are currently any
    -- enabled functions in section
    if __pre_hooks[script] then
        if __pre_hook_cache:section_count(script) > 0 then
            gm.hook_enable(__pre_hooks[script])
        else gm.hook_disable(__pre_hooks[script])
        end
        return
    end

    -- Script
    if type(script) == "number" then
        __pre_hooks[script] = gm.pre_script_hook(script, function(self, other, result, args)
            -- Wrap args
            local _self     = Wrap.wrap(self)
            local _other    = Wrap.wrap(other)
            local _result   = { value = nil }
            local _args     = {}
            local _args_og  = {}
            for i, arg in ipairs(args) do
                local wrap = Wrap.wrap(arg.value)
                _args[i]    = { value = wrap }
                _args_og[i] = wrap
            end

            local pre_hook_return = true

            -- Call registered functions with wrapped args
            __pre_hook_cache:loop_and_call_functions(function(fn_table)
                local status, err = pcall(fn_table.fn, _self, _other, _result, _args)
                if not status then
                    if (err == nil)
                    or (err == "C++ exception") then err = "GameMaker error (see above)" end
                    log.warning("\n"..fn_table.namespace..": Pre-hook (ID '"..fn_table.id.."') of function '"..(gm.constants_type_sorted["script"][script] or gm.constants_type_sorted["gml_script"][script] or script).."' failed to execute fully.\n"..err)
                else
                    -- Allow `return false` to prevent normal function execution
                    if err == false then pre_hook_return = false end
                end
            end, script)

            -- Args modification
            for i, arg in ipairs(_args) do
                if (type(arg) == "table") and (arg.value ~= _args_og[i]) then
                    args[i].value = Wrap.unwrap(arg.value)
                end
            end

            return pre_hook_return
        end)

    -- Object
    else
        __pre_hooks[script] = gm.pre_code_execute(script, function(self, other)
            -- Wrap args
            local _self     = Wrap.wrap(self)
            local _other    = Wrap.wrap(other)

            local pre_hook_return = true

            -- Call registered functions with wrapped args
            __pre_hook_cache:loop_and_call_functions(function(fn_table)
                local status, err = pcall(fn_table.fn, _self, _other)
                if not status then
                    if (err == nil)
                    or (err == "C++ exception") then err = "GameMaker error (see above)" end
                    log.warning("\n"..fn_table.namespace..": Pre-hook (ID '"..fn_table.id.."') of function '"..script.."' failed to execute fully.\n"..err)
                else
                    -- Allow `return false` to prevent normal function execution
                    if err == false then pre_hook_return = false end
                end
            end, script)

            return pre_hook_return
        end)

    end
end


Hook.internal.manage_post_hook = function(script)
    -- Enable/disable existing hook based on
    -- whether or not there are currently any
    -- enabled functions in section
    if __post_hooks[script] then
        if __post_hook_cache:section_count(script) > 0 then
            gm.hook_enable(__post_hooks[script])
        else gm.hook_disable(__post_hooks[script])
        end
        return
    end

    -- Script
    if type(script) == "number" then
        __post_hooks[script] = gm.post_script_hook(script, function(self, other, result, args)
            -- Wrap args
            local _self     = Wrap.wrap(self)
            local _other    = Wrap.wrap(other)
            local _result   = { value = Wrap.wrap(result.value) }   -- Allow detecting modification
            local _result_og = _result.value
            local _args     = {}
            for i, arg in ipairs(args) do
                _args[i] = { value = Wrap.wrap(arg.value) }
            end

            -- Call registered functions with wrapped args
            __post_hook_cache:loop_and_call_functions(function(fn_table)
                local status, err = pcall(fn_table.fn, _self, _other, _result, _args)
                if not status then
                    if (err == nil)
                    or (err == "C++ exception") then err = "GameMaker error (see above)" end
                    log.warning("\n"..fn_table.namespace..": Post-hook (ID '"..fn_table.id.."') of function '"..(gm.constants_type_sorted["script"][script] or gm.constants_type_sorted["gml_script"][script] or script).."' failed to execute fully.\n"..err)
                end
            end, script)

            -- Result modification
            if _result.value ~= _result_og then
                result.value = Wrap.unwrap(_result.value)
            end
        end)

    -- Object
    else
        __post_hooks[script] = gm.post_code_execute(script, function(self, other)
            -- Wrap args
            local _self     = Wrap.wrap(self)
            local _other    = Wrap.wrap(other)

            -- Call registered functions with wrapped args
            __post_hook_cache:loop_and_call_functions(function(fn_table)
                local status, err = pcall(fn_table.fn, _self, _other)
                if not status then
                    if (err == nil)
                    or (err == "C++ exception") then err = "GameMaker error (see above)" end
                    log.warning("\n"..fn_table.namespace..": Post-hook (ID '"..fn_table.id.."') of function '"..script.."' failed to execute fully.\n"..err)
                end
            end, script)
        end)

    end
end


Hook.internal.readd_hooks = function()
    for script, _ in pairs(__pre_hooks) do
        gm.hook_disable(__pre_hooks[script])
        __pre_hooks[script] = nil
        Hook.internal.manage_pre_hook(script)
    end
    for script, _ in pairs(__post_hooks) do
        gm.hook_disable(__post_hooks[script])
        __post_hooks[script] = nil
        Hook.internal.manage_post_hook(script)
    end
end

run_on_hotload(function()
    table.insert(_rapi_initialize, Hook.internal.readd_hooks)
end)



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       Hook
--@param        script      | number or string  | The game function to hook. <br>(E.g., `gm.constants.instance_number`, `"gml_Object_oOptionsMenu_Create_0"`, etc.)
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args` for script hooks, <br>and `self, other` for object hooks.
--@overload
--@return       Hook
--@param        script      | number or string  | The game function to hook. <br>(E.g., `gm.constants.instance_number`, `"gml_Object_oOptionsMenu_Create_0"`, etc.)
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args` for script hooks, <br>and `self, other` for object hooks.
--[[
Registers a function under a game function pre-hook
Returns a Hook wrapper of the unique ID of the registered function.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.

*Technical:* Uses `gm.pre_script_hook` (script) or `gm.pre_code_execute` (object) internally, passing auto-wrapped values.
]]
Hook.add_pre = function(NAMESPACE, script, arg2, arg3)
    -- Throw error if script is banned
    if Util.table_has(banned_scripts, script) then log.error("Hook.add_pre: The function '"..(gm.constants_type_sorted["script"][script] or gm.constants_type_sorted["gml_script"][script] or script).."' is not permitted to be hooked", 2) end

    -- Throw error if script argument is invalid
    if  (type(script) ~= "number")
    and (type(script) ~= "string") then log.error("Hook.add_pre: script is invalid", 2) end

    -- Throw error if not function
    if  (type(arg2) ~= "function")
    and (type(arg3) ~= "function") then
        log.error("Hook.add_pre: No function provided", 2)
    end

    __hook_current_id = __hook_current_id + 1

    local wrapper
    if type(arg2) == "function" then
        wrapper = Hook.wrap(__pre_hook_cache:add(arg2, NAMESPACE, 0, script, __hook_current_id))
    else wrapper = Hook.wrap(__pre_hook_cache:add(arg3, NAMESPACE, arg2, script, __hook_current_id))
    end

    -- Create actual hook
    Hook.internal.manage_pre_hook(script)

    return wrapper
end


--@static
--@return       Hook
--@param        script      | number or string  | The game function to hook. <br>(E.g., `gm.constants.instance_number`, `"gml_Object_oOptionsMenu_Create_0"`, etc.)
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args` for script hooks, <br>and `self, other` for object hooks.
--@overload
--@return       Hook
--@param        script      | number or string  | The game function to hook. <br>(E.g., `gm.constants.instance_number`, `"gml_Object_oOptionsMenu_Create_0"`, etc.)
--@param        priority    | number    | The priority of the function. <br>Higher values run before lower ones; can be negative. <br>`Callback.Priority.NORMAL` (`0`) by default.
--@param        fn          | function  | The function to register. <br>The parameters for it are `self, other, result, args` for script hooks, <br>and `self, other` for object hooks.
--[[
Registers a function under a game function post-hook
Returns a Hook wrapper of the unique ID of the registered function.

**Priority Convention**
To allow for a decent amount of space between priorities,
use the enum values in @link {`Callback.Priority` | Callback#Priority}.
If you need to be more specific than that, try to keep a distance of at least `100`.

*Technical:* Uses `gm.post_script_hook` (script) or `gm.post_code_execute` (object) internally, passing auto-wrapped values.
]]
Hook.add_post = function(NAMESPACE, script, arg2, arg3)
    -- Throw error if script is banned
    if Util.table_has(banned_scripts, script) then log.error("Hook.add_post: The function '"..(gm.constants_type_sorted["script"][script] or gm.constants_type_sorted["gml_script"][script] or script).."' is not permitted to be hooked", 2) end

    -- Throw error if script argument is invalid
    if  (type(script) ~= "number")
    and (type(script) ~= "string") then log.error("Hook.add_post: script is invalid", 2) end

    -- Throw error if not function
    if  (type(arg2) ~= "function")
    and (type(arg3) ~= "function") then
        log.error("Hook.add_post: No function provided", 2)
    end

    __hook_current_id = __hook_current_id + 1

    local wrapper
    if type(arg2) == "function" then
        wrapper = Hook.wrap(__post_hook_cache:add(arg2, NAMESPACE, 0, script, __hook_current_id))
    else wrapper = Hook.wrap(__post_hook_cache:add(arg3, NAMESPACE, arg2, script, __hook_current_id))
    end

    -- Create actual hook
    Hook.internal.manage_post_hook(script)

    return wrapper
end


--@static
--[[
Removes all registered hook functions from your namespace.

Automatically called when you hotload your mod.
]]
Hook.remove_all = function(NAMESPACE)
    __pre_hook_cache:remove_all(NAMESPACE)
    __post_hook_cache:remove_all(NAMESPACE)
end
table.insert(_clear_namespace_functions, Hook.remove_all)


--@static
--@return       Hook
--@param        id          | number    | The hook function ID to wrap.
--[[
Returns a Hook wrapper containing the provided hook function ID.
]]
Hook.wrap = function(id)
    -- Input:   number or Hook wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(id), metatable_hook)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_hook = {

    --@instance
    --@return       function
    --[[
    Removes and returns the registered hook function.
    ]]
    remove = function(self)
        local fn_table_pre  = __pre_hook_cache.id_lookup[self.value]
        if fn_table_pre then
            local fn = __pre_hook_cache:remove(self.value)
            Hook.internal.manage_pre_hook(fn_table_pre.section)
            return fn
        end

        local fn_table_post = __post_hook_cache.id_lookup[self.value]
        if fn_table_post then
            local fn = __post_hook_cache:remove(self.value)
            Hook.internal.manage_post_hook(fn_table_post.section)
            return fn
        end
    end,


    --@instance
    --@return       bool
    --[[
    Returns `true` if the hook function is enabled.
    ]]
    is_enabled = function(self)
        local fn_table_pre  = __pre_hook_cache.id_lookup[self.value]
        local fn_table_post = __post_hook_cache.id_lookup[self.value]

        return (fn_table_pre and fn_table_pre.enabled)
            or (fn_table_post and fn_table_post.enabled)
            or false
    end,


    --@instance
    --@param        bool        | bool      | `true` - Enable function <br>`false` - Disable function
    --[[
    Toggles the enabled status of the registered hook function.
    ]]
    toggle = function(self, bool)
        if type(bool) ~= "boolean" then log.error("toggle: bool is invalid", 2) end

        local fn_table_pre  = __pre_hook_cache.id_lookup[self.value]
        if fn_table_pre then
            __pre_hook_cache:toggle(self.value, bool)
            Hook.internal.manage_pre_hook(fn_table_pre.section)
            return
        end

        local fn_table_post = __post_hook_cache.id_lookup[self.value]
        if fn_table_post then
            __post_hook_cache:toggle(self.value, bool)
            Hook.internal.manage_post_hook(fn_table_post.section)
            return
        end
    end

}



-- ========== Metatables ==========

local wrapper_name = "Hook"

make_table_once("metatable_hook", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        
        -- Methods
        if methods_hook[k] then
            return methods_hook[k]
        end
    end,
    

    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end
        
        log.error(wrapper_name.." has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



__class.Hook = Hook