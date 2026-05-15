-- Hook

---@class Hook
Hook = new_class()
C.Hook = Hook

run_on_initial_load(function()
    P.pre_hooks           = {}  ---@type table<script, integer> Stores return IDs of `gm.pre_script_hook`s.
    P.post_hooks          = {}  ---@type table<script, integer> Stores return IDs of `gm.post_script_hook`s.
    P.pre_hook_functions  = {}  ---@type table<script, CallbackTable>
    P.post_hook_functions = {}  ---@type table<script, CallbackTable>
    P.hook_counter        = {value = 0} -- Shared counter for all hook `CallbackTable`s.
    P.hook_id_to_table    = {}  ---@type table<integer, CallbackTable> Stores which CallbackTable a function is in.
end)

-- Scripts that are (potentially) bad for performance
local banned_scripts = table.set{
    gm.constants.step_actor,
    gm.constants.draw_actor,
    gm.constants.step_buff,
    gm.constants.actor_heal_raw,
}

local queue_manage = {} ---@type table<script, boolean>

local proxy = P.proxy
local metatable

local type        = type
local tostring    = tostring
local pcall       = pcall
local ipairs      = ipairs
local log_warning = log.warning
local new_proxy   = new_proxy
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

    local hook_functions = P.pre_hook_functions[script]

    -- Script
    if type(script) == "number" then
        P.pre_hooks[script] = gm.pre_script_hook(script, function(self, other, result, args)
            -- Call registered functions
            local hook_return = true

            for i = 1, #hook_functions do
                local data = hook_functions[i]
                if data.enabled then
                    local status, out = pcall(data.fn, self, other, result, args)
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

            return hook_return
        end)

    -- Object event
    else
        P.pre_hooks[script] = gm.pre_code_execute(script, function(self, other)
            -- Call registered functions
            local hook_return = true

            for i = 1, #hook_functions do
                local data = hook_functions[i]
                if data.enabled then
                    local status, out = pcall(data.fn, self, other)
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

    local hook_functions = P.post_hook_functions[script]

    -- Script
    if type(script) == "number" then
        P.post_hooks[script] = gm.post_script_hook(script, function(self, other, result, args)
            -- Call registered functions
            for i = 1, #hook_functions do
                local data = hook_functions[i]
                if data.enabled then
                    local status, out = pcall(data.fn, self, other, result, args)
                    if not status then
                        if out == nil
                        or out == "C++ exception" then
                            out = "GameMaker error (see above)"
                        end
                        log.warning("\n| "..data.namespace..": Error in post-hook of script '"..get_script_name(script).."' (ID "..math.floor(data.id)..")\n| "..out)
                    end
                end
            end
        end)

    -- Object event
    else
        P.post_hooks[script] = gm.post_code_execute(script, function(self, other)
            -- Call registered functions
            for i = 1, #hook_functions do
                local data = hook_functions[i]
                if data.enabled then
                    local status, out = pcall(data.fn, self, other)
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
        P.pre_hooks[script] = nil
        manage_pre_hook(script)
    end
    for script, hook in pairs(P.post_hooks) do
        P.post_hooks[script] = nil
        manage_post_hook(script)
    end
end)


-- ========== Static Methods ==========

--[[
Registers a function to run before a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned to the function.

*Technical:* Uses `gm.pre_script_hook` (script) or `gm.pre_code_execute` (object event) internally, passing wrapped values.
]]
---@param script number | string The GameMaker script or object event to hook.
---@param fn function The function to register. <br>The parameters for it should be: <br>Script hooks - `self, other, result, args` <br>Object hooks - `self, other`
---@return Hook
Hook.add_pre = function(NAMESPACE, script, fn) end

--[[
Registers a function to run before a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned to the function.

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
        throw("'"..get_script_name(script).."' is not permitted to be hooked", "add_pre")
    end

    -- Check if script argument is invalid
    local _type = type(script)
    if  _type ~= "number"
    and _type ~= "string" then
        throw("Script '"..tostring(script).."' is invalid", "add_pre")
    end

    -- Create new CallbackTable for the script if it does not exist
    local hook_table = P.pre_hook_functions[script]
    if not hook_table then
        hook_table = CallbackTable.new(P.hook_counter)
        P.pre_hook_functions[script] = hook_table
    end

    local value, wrapper
    local _type = type(priority)
    if _type == "function" then
        value   = hook_table:add(priority, NAMESPACE)
        wrapper = Hook.wrap(value)
    else
        if _type    ~= "number"   then throw("Priority should be a number", "add_pre") end
        if type(fn) ~= "function" then throw("No function provided", "add_pre") end
        value   = hook_table:add(fn, NAMESPACE, priority)
        wrapper = Hook.wrap(value)
    end
    P.hook_id_to_table[value] = hook_table

    hook_table.script = script
    manage_pre_hook(script)

    return wrapper
end

--[[
Registers a function to run after a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned to the function.

*Technical:* Uses `gm.post_script_hook` (script) or `gm.post_code_execute` (object event) internally, passing wrapped values.
]]
---@param script number | string The GameMaker script or object event to hook.
---@param fn function The function to register. <br>The parameters for it should be: <br>Script hooks - `self, other, result, args` <br>Object hooks - `self, other`
---@return Hook
Hook.add_post = function(NAMESPACE, script, fn) end

--[[
Registers a function to run after a GameMaker script or object event. <br>
Returns a Hook wrapper for the unique ID assigned to the function.

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
        throw("'"..get_script_name(script).."' is not permitted to be hooked", "add_post")
    end

    -- Check if script argument is invalid
    local _type = type(script)
    if  _type ~= "number"
    and _type ~= "string" then
        throw("Script '"..tostring(script).."' is invalid", "add_post")
    end

    -- Create new CallbackTable for the script if it does not exist
    local hook_table = P.post_hook_functions[script]
    if not hook_table then
        hook_table = CallbackTable.new(P.hook_counter)
        P.post_hook_functions[script] = hook_table
    end

    local value, wrapper
    local _type = type(priority)
    if _type == "function" then
        value   = hook_table:add(priority, NAMESPACE)
        wrapper = Hook.wrap(value)
    else
        if _type    ~= "number"   then throw("Priority should be a number", "add_post") end
        if type(fn) ~= "function" then throw("No function provided", "add_post") end
        value   = hook_table:add(fn, NAMESPACE, priority)
        wrapper = Hook.wrap(value)
    end
    P.hook_id_to_table[value] = hook_table

    hook_table.script = script
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
            queue_manage[script] = true
        end
    end
    for script, t in pairs(P.post_hook_functions) do
        if t:remove_all(NAMESPACE) > 0 then
            queue_manage[script] = true
        end
    end
end
run_on_import(Hook.remove_all)

--[[
Returns a Hook wrapper containing the provided hook function ID.
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
    queue_manage[t.script] = true
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
    if type(value) ~= "boolean" then throw("value must be a bool") end
    local id = proxy[self]
    local t  = P.hook_id_to_table[id]
    queue_manage[t.script] = true
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


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.__input_system_tick, function(self, other, result, args)
    for scr, _ in pairs(queue_manage) do
        if P.pre_hooks[scr]  then manage_pre_hook(scr) end
        if P.post_hooks[scr] then manage_post_hook(scr) end
    end
    queue_manage = {}
end)