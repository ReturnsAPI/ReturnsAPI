-- Hook

---@class Hook
Hook = new_class()
C.Hook = Hook

run_on_initial_load(function()
    P.pre_hooks           = {}  ---@type table<script, integer> Stores return IDs of `gm.pre_script_hook`s
    P.post_hooks          = {}  ---@type table<script, integer> Stores return IDs of `gm.post_script_hook`s
    P.pre_hook_functions  = {}  ---@type table<script, CallbackTable>
    P.post_hook_functions = {}  ---@type table<script, CallbackTable>
    P.hook_counter        = {value = 0} -- Shared counter for all hook `CallbackTable`s
    P.hook_id_to_table    = {}  ---@type table<integer, CallbackTable> Stores which CallbackTable a function is in.
end)

-- Scripts that are (potentially) bad for performance
local banned_scripts = {
    [gm.constants.step_actor]     = true,
    [gm.constants.draw_actor]     = true,
    [gm.constants.step_buff]      = true,
    [gm.constants.actor_heal_raw] = true,
}

local proxy = P.proxy
local metatable

local type        = type
local tostring    = tostring
local pcall       = pcall
local ipairs      = ipairs
local log_warning = log.warning
local new_proxy   = new_proxy
local wrap        = Wrap.wrap
local unwrap      = Wrap.unwrap


-- ========== Private Methods ==========

local function get_script_name(script)
    return gm.constants_type_sorted["script"][script]
        or gm.constants_type_sorted["gml_script"][script]
        or script
end

--[[
Manages creation and toggling of a pre-hook.
]]
local function manage_pre_hook(script)
    -- Enable/disable existing hook based
    -- on if there are any enabled functions
    local hook_id = P.pre_hooks[script]
    if hook_id then
        if P.pre_hook_functions[script].enabled_count > 0 then
            gm.hook_enable(hook_id)
        else gm.hook_disable(hook_id)
        end
        return
    end

    -- Script
    if type(script) == "number" then
        P.pre_hooks[script] = gm.pre_script_hook(script, function(self, other, result, args)
            -- Wrap args
            local _self    = wrap(self)
            local _other   = wrap(other)
            local _result  = { value = nil }
            local _args    = {}
            local _args_og = {}

            for i, arg in ipairs(args) do
                local wrap = { value = wrap(arg.value) }
                _args[i]    = wrap
                _args_og[i] = wrap
            end

            -- Call registered functions
            local hook_return = true

            for i, data in ipairs(P.pre_hook_functions[script]) do
                if data.enabled then
                    local status, out = pcall(data.fn, _self, _other, _result, _args)
                    if not status then
                        if out == nil
                        or out == "C++ exception" then
                            out = "GameMaker error (see above)"
                        end
                        log.warning("\n| "..data.namespace..": Error in pre-hook of script '"..get_script_name(script).."' (ID "..math.floor(data.id)..")\n| "..out)
                    else
                        -- Prevent normal function execution if returned `false`
                        if out == false then hook_return = false end
                    end
                end
            end

            -- Args modification
            for i, arg in ipairs(_args) do
                local og = _args_og[i]
                if  arg == og
                and arg.value ~= og.value then
                    args[i].value = unwrap(arg.value)
                end
            end

            return hook_return
        end)

    -- Object event
    else
        P.pre_hooks[script] = gm.pre_code_execute(script, function(self, other)
            -- Wrap args
            local _self  = wrap(self)
            local _other = wrap(other)

            -- Call registered functions
            local hook_return = true

            for i, data in ipairs(P.pre_hook_functions[script]) do
                if data.enabled then
                    local status, out = pcall(data.fn, _self, _other)
                    if not status then
                        if out == nil
                        or out == "C++ exception" then
                            out = "GameMaker error (see above)"
                        end
                        log.warning("\n| "..data.namespace..": Error in pre-hook of object event '"..get_script_name(script).."' (ID "..math.floor(data.id)..")\n| "..out)
                    else
                        -- Prevent normal function execution if returned `false`
                        if out == false then hook_return = false end
                    end
                end
            end

            return hook_return
        end)
        
    end
end

--[[
Manages creation and toggling of a post-hook.
]]
local function manage_post_hook(script)
    -- Enable/disable existing hook based
    -- on if there are any enabled functions
    local hook_id = P.post_hooks[script]
    if hook_id then
        if P.post_hook_functions[script].enabled_count > 0 then
            gm.hook_enable(hook_id)
        else gm.hook_disable(hook_id)
        end
        return
    end

    -- Script
    if type(script) == "number" then
        P.post_hooks[script] = gm.post_script_hook(script, function(self, other, result, args)
            -- Wrap args
            local _self      = wrap(self)
            local _other     = wrap(other)
            local _result_og = wrap(result.value)
            local _result    = { value = _result_og }
            local _args      = {}

            for i, arg in ipairs(args) do
                _args[i] = { value = wrap(arg.value) }
            end

            -- Call registered functions
            for i, data in ipairs(P.post_hook_functions[script]) do
                if data.enabled then
                    local status, out = pcall(data.fn, _self, _other, _result, _args)
                    if not status then
                        if out == nil
                        or out == "C++ exception" then
                            out = "GameMaker error (see above)"
                        end
                        log.warning("\n| "..data.namespace..": Error in post-hook of script '"..get_script_name(script).."' (ID "..math.floor(data.id)..")\n| "..out)
                    end
                end
            end

            -- Result modification
            if _result.value ~= _result_og then
                result.value = unwrap(_result.value)
            end
        end)

    -- Object event
    else
        P.post_hooks[script] = gm.post_code_execute(script, function(self, other)
            -- Wrap args
            local _self  = wrap(self)
            local _other = wrap(other)

            -- Call registered functions
            for i, data in ipairs(P.post_hook_functions[script]) do
                if data.enabled then
                    local status, out = pcall(data.fn, _self, _other)
                    if not status then
                        if out == nil
                        or out == "C++ exception" then
                            out = "GameMaker error (see above)"
                        end
                        log.warning("\n| "..data.namespace..": Error in post-hook of object event '"..get_script_name(script).."' (ID "..math.floor(data.id)..")\n| "..out)
                    end
                end
            end
        end)
        
    end
end

run_on_hotload(function()
    -- Readd hooks
    for script, hook in pairs(P.pre_hooks) do
        gm.hook_disable(hook)
        P.pre_hooks[script] = nil
        manage_pre_hook(script)
    end
    for script, hook in pairs(P.post_hooks) do
        gm.hook_disable(hook)
        P.post_hooks[script] = nil
        manage_post_hook(script)
    end
end)


-- ========== Static Methods ==========

--[[
Registers a function to run before a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned.

*Technical:* Uses `gm.pre_script_hook` (script) or `gm.pre_code_execute` (object event) internally, passing wrapped values.
]]
---@param script number | string The GameMaker script or object event to hook.
---@param fn function The function to register. <br>The parameters for it should be: <br>Script hooks - `self, other, result, args` <br>Object hooks - `self, other`
---@return Hook
Hook.add_pre = function(NAMESPACE, script, fn) end

--[[
Registers a function to run before a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.

*Technical:* Uses `gm.pre_script_hook` (script) or `gm.pre_code_execute` (object event) internally, passing wrapped values.
]]
---@param script number | string The GameMaker script or object event to hook.
---@param priority integer The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
---@param fn function The function to register. <br>The parameters for it should be: <br>Script hooks - `self, other, result, args` <br>Object hooks - `self, other`
---@return Hook
Hook.add_pre = function(NAMESPACE, script, priority, fn)
    -- Check if script is banned
    if banned_scripts[script] then
        throw("The function '"..get_script_name(script).."' is not permitted to be hooked")
    end

    -- Check if script argument is invalid
    if  type(script) ~= "number"
    and type(script) ~= "string" then
        throw("Script '"..tostring(script).."' is invalid")
    end

    local hook_table = P.pre_hook_functions[script]
    if not hook_table then
        hook_table = CallbackTable.new(P.hook_counter)
        P.pre_hook_functions[script] = hook_table
    end

    local value, wrapper
    if type(priority) == "function" then
        value   = hook_table:add(priority, NAMESPACE)
        wrapper = Hook.wrap(value)
    else
        if type(priority) ~= "number"   then throw("Priority should be a number") end
        if type(fn)       ~= "function" then throw("No function provided") end
        value   = hook_table:add(fn, NAMESPACE, priority)
        wrapper = Hook.wrap(value)
    end
    P.hook_id_to_table[value] = hook_table

    manage_pre_hook(script)

    return wrapper
end

--[[
Registers a function to run after a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned.

*Technical:* Uses `gm.post_script_hook` (script) or `gm.post_code_execute` (object event) internally, passing wrapped values.
]]
---@param script number | string The GameMaker script or object event to hook.
---@param fn function The function to register. <br>The parameters for it should be: <br>Script hooks - `self, other, result, args` <br>Object hooks - `self, other`
---@return Hook
Hook.add_post = function(NAMESPACE, script, fn) end

--[[
Registers a function to run after a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.

*Technical:* Uses `gm.post_script_hook` (script) or `gm.post_code_execute` (object event) internally, passing wrapped values.
]]
---@param script number | string The GameMaker script or object event to hook.
---@param priority integer The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
---@param fn function The function to register. <br>The parameters for it should be: <br>Script hooks - `self, other, result, args` <br>Object hooks - `self, other`
---@return Hook
Hook.add_post = function(NAMESPACE, script, priority, fn)
    -- Check if script is banned
    if banned_scripts[script] then
        throw("The function '"..get_script_name(script).."' is not permitted to be hooked")
    end

    -- Check if script argument is invalid
    if  type(script) ~= "number"
    and type(script) ~= "string" then
        throw("Script '"..tostring(script).."' is invalid")
    end

    local hook_table = P.post_hook_functions[script]
    if not hook_table then
        hook_table = CallbackTable.new(P.hook_counter)
        P.post_hook_functions[script] = hook_table
    end

    local value, wrapper
    if type(priority) == "function" then
        value   = hook_table:add(priority, NAMESPACE)
        wrapper = Hook.wrap(value)
    else
        if type(priority) ~= "number"   then throw("Priority should be a number") end
        if type(fn)       ~= "function" then throw("No function provided") end
        value   = hook_table:add(fn, NAMESPACE, priority)
        wrapper = Hook.wrap()
    end
    P.hook_id_to_table[value] = hook_table

    manage_post_hook(script)

    return wrapper
end

--[[
Removes all registered functions in your namespace.

Automatically called when you hotload your mod.
]]
Hook.remove_all = function(NAMESPACE)
    for script, t in pairs(P.pre_hook_functions) do
        if t:remove_all(NAMESPACE) > 0 then
            manage_pre_hook(script)
        end
    end
    for script, t in pairs(P.post_hook_functions) do
        if t:remove_all(NAMESPACE) > 0 then
            manage_post_hook(script)
        end
    end
end

--[[
Returns a Hook wrapper containing the provided array.
]]
---@param hook Hook | integer The hook to wrap.
---@return Hook
Hook.wrap = function(hook)
    return new_proxy(unwrap(hook), metatable)
end


-- ========== Wrapper Methods ==========

---@class Hook
local methods = {}

--[[
Removes and returns the function.
]]
---@return function
methods.remove = function(self)
    local id = proxy[self]
    local t  = P.hook_id_to_table[id]
    return t:remove(id)
end

--[[
Returns `true` if the function is enabled.
]]
---@return boolean enabled
methods.is_enabled = function(self)
    local id   = proxy[self]
    local t    = P.hook_id_to_table[id]
    local data = t.id_lookup[id]
    return data.enabled
end

--[[
Enables/disables the function.
]]
---@param value boolean
methods.toggle = function(self, value)
    local id = proxy[self]
    local t  = P.hook_id_to_table[id]
    t:toggle(id, value)
end


-- ========== Metatables ==========

---@class Hook
---@field value integer
---@field RAPI string

local mt_name = "Hook"

W.Hook = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        if methods[k] then return methods[k] end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Hook