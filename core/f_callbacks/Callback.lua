-- Callback

---@class Callback
Callback = new_class()
C.Callback = Callback

run_on_initial_load(function()
    P.callback_functions      = {}  ---@type table<number, CallbackTable>
    P.callback_counter        = {value = 0} -- Shared counter for all callback `CallbackTable`s.
    P.callback_id_to_table    = {}  ---@type table<number, CallbackTable> Stores which CallbackTable a function is in.
    
    P.callback_custom         = FindTable.new()
    P.callback_custom_counter = 0   -- Next usable custom callback ID; `Callback.CUSTOM_START` is added to this.
end)

local callback_functions = P.callback_functions
local callback_custom    = P.callback_custom

local callback_arg_types = {}  ---@type table<number, table<number, string>> Contains argument types for callbacks `0` to `42`.
local callback_constants = {}  ---@type table<number, string> Array table of callback types `0` to `42` (indexed from `1`).

local proxy = P.proxy
local metatable_type
local metatable_function

local type         = type
local new_proxy    = new_proxy
local table_unpack = table.unpack
local wrap         = Wrap.wrap
local unwrap       = Wrap.unwrap

local args_holders = {}     -- Reusable tables for arg holders
local args_holder_rsp = 0   -- Index of most recently used; increment before taking
for i = 1, 128 do args_holders[i] = {} end


-- ========== Constants and Enums ==========

Callback.ON_LOAD                            = 0
Callback.POST_LOAD                          = 1
Callback.ON_STEP                            = 2
Callback.PRE_STEP                           = 3
Callback.POST_STEP                          = 4
Callback.ON_DRAW                            = 5
Callback.PRE_HUD_DRAW                       = 6
Callback.ON_HUD_DRAW                        = 7
Callback.POST_HUD_DRAW                      = 8
Callback.CAMERA_ON_VIEW_CAMERA_UPDATE       = 9
Callback.ON_SCREEN_REFRESH                  = 10
Callback.ON_GAME_START                      = 11
Callback.ON_GAME_END                        = 12
Callback.ON_DIRECTOR_POPULATE_SPAWN_ARRAYS  = 13
Callback.ON_STAGE_START                     = 14
Callback.ON_SECOND                          = 15
Callback.ON_MINUTE                          = 16
Callback.ON_ATTACK_CREATE                   = 17
Callback.ON_ATTACK_HIT                      = 18
Callback.ON_ATTACK_HANDLE_START             = 19
Callback.ON_ATTACK_HANDLE_END               = 20
Callback.ON_DAMAGE_BLOCKED                  = 21
Callback.ON_ENEMY_INIT                      = 22
Callback.ON_ELITE_INIT                      = 23
Callback.ON_DEATH                           = 24
Callback.ON_PLAYER_INIT                     = 25
Callback.ON_PLAYER_STEP                     = 26
Callback.PRE_PLAYER_HUD_DRAW                = 27
Callback.ON_PLAYER_HUD_DRAW                 = 28
Callback.ON_PLAYER_INVENTORY_UPDATE         = 29
Callback.ON_PLAYER_DEATH                    = 30
Callback.ON_CHECKPOINT_RESPAWN              = 31
Callback.ON_INPUT_PLAYER_DEVICE_UPDATE      = 32
Callback.ON_PICKUP_COLLECTED                = 33
Callback.ON_PICKUP_ROLL                     = 34
Callback.ON_EQUIPMENT_USE                   = 35
Callback.POST_EQUIPMENT_USE                 = 36
Callback.ON_INTERACTABLE_ACTIVATE           = 37
Callback.ON_HIT_PROC                        = 38
Callback.ON_DAMAGED_PROC                    = 39
Callback.ON_KILL_PROC                       = 40
Callback.NET_MESSAGE_ON_RECEIVED            = 41
Callback.CONSOLE_ON_COMMAND                 = 42

-- Populate `callback_constants`
for name, type_id in pairs(Callback) do
    if type(type_id) == "number" then
        callback_constants[type_id + 1] = name
    end
end

-- Custom callbacks

Callback.CUSTOM_START      = 10000

Callback.ON_HEAL           = 10000
Callback.ON_SHIELD_BREAK   = 10001
Callback.ON_SHIELD_RESTORE = 10002
Callback.ON_SKILL_ACTIVATE = 10003
Callback.ON_EQUIPMENT_SWAP = 10004

Callback.Priority = {
    NORMAL = 0,
    BEFORE = 1000,
    AFTER  = -1000,
}
Callback.internal.FIRST = math.huge


-- ========== Internal ==========

-- Called at the bottom of this file since it does wrapping
local function populate_arg_types()
    ---@type Array
    local class_callback = Global.class_callback

    for type_id, name in ipairs(callback_constants) do
        -- Generate list of argument types for each callback
        callback_arg_types[type_id - 1] = {}

        ---@type Array
        local arg_types = class_callback:get(type_id - 1):get(2)
        for i, v in ipairs(arg_types) do
            table.insert(callback_arg_types[type_id - 1], v)
        end

        -- Populate find table with vanilla callbacks
        local identifier = name:lower()
        while true do
            -- E.g., ON_STAGE_START -> onStageStart
            local pos = identifier:find("_")
            if not pos then break end
            identifier = identifier:sub(1, pos - 1)..identifier:sub(pos + 1, pos + 1):upper()..identifier:sub(pos + 2, -1)
        end
        local wrapper = Callback.wrap_type(type_id - 1)
        callback_custom:set(wrapper, identifier, "ror", type_id - 1)
    end
end


-- ========== Static Methods (Function) ==========

--[[
Registers a function under a callback type. <br>
Returns a CallbackFunction wrapper for the unique ID assigned to the function.
]]
---@param callback number | CallbackType The callback type to register under.
---@param fn function The function to register. <br>The parameters for it depend on the callback type.
---@return CallbackFunction
Callback.add = function(NAMESPACE, callback, fn) end

--[[
Registers a function under a callback type. <br>
Returns a CallbackFunction wrapper for the unique ID assigned to the function.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
---@param callback number | CallbackType The callback type to register under.
---@param priority number The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
---@param fn function The function to register. <br>The parameters for it depend on the callback type.
---@return CallbackFunction
Callback.add = function(NAMESPACE, callback, priority, fn)
    -- Check if callback type is invalid
    callback = unwrap(callback)
    if type(callback) ~= "number" then
        throw("Callback type '"..tostring(callback).."' is invalid", "add")
    end

    -- Create new CallbackTable for the callback type if it does not exist
    local cb_table = callback_functions[callback]
    if not cb_table then
        cb_table = CallbackTable.new(P.callback_counter)
        callback_functions[callback] = cb_table
    end

    local value, wrapper
    local _type = type(priority)
    if _type == "function" then
        value   = cb_table:add(priority, NAMESPACE)
        wrapper = Callback.wrap_function(value)
    else
        if _type    ~= "number"   then throw("Priority should be a number", "add") end
        if type(fn) ~= "function" then throw("No function provided", "add") end
        value   = cb_table:add(fn, NAMESPACE, priority)
        wrapper = Callback.wrap_function(value)
    end
    P.callback_id_to_table[value] = cb_table

    return wrapper
end

--[[
Variant of @link {`Callback.add` | Callback#add} that passes `self, other` <br>
as the first two arguments to the callback function, <br>
which may have useful context for some callback types.
]]
---@param callback number | CallbackType The callback type to register under.
---@param fn function The function to register. <br>The parameters for it depend on the callback type.
---@return CallbackFunction
Callback.add_SO = function(NAMESPACE, callback, fn) end

--[[
Variant of @link {`Callback.add` | Callback#add} that passes `self, other` <br>
as the first two arguments to the callback function, <br>
which may have useful context for some callback types.

**Priority Convention** <br>
To allow for a decent amount of space between priorities, <br>
use the enum values in @link {`Callback.Priority` | Callback#Priority}. <br>
If you need to be more specific than that, try to keep a distance of at least `100`.
]]
---@param callback number | CallbackType The callback type to register under.
---@param priority number The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
---@param fn function The function to register. <br>The parameters for it depend on the callback type.
---@return CallbackFunction
Callback.add_SO = function(NAMESPACE, callback, priority, fn)
    -- Check if callback type is invalid
    callback = unwrap(callback)
    if type(callback) ~= "number" then
        throw("Callback type '"..tostring(callback).."' is invalid", "add_SO")
    end

    -- Create new CallbackTable for the callback type if it does not exist
    local cb_table = callback_functions[callback]
    if not cb_table then
        cb_table = CallbackTable.new(P.callback_counter)
        callback_functions[callback] = cb_table
    end

    local value, wrapper
    local _type = type(priority)
    if _type == "function" then
        value, data = cb_table:add(priority, NAMESPACE)
        wrapper     = Callback.wrap_function(value)
        data.SO     = true
    else
        if _type    ~= "number"   then throw("Priority should be a number", "add_SO") end
        if type(fn) ~= "function" then throw("No function provided", "add_SO") end
        value, data = cb_table:add(fn, NAMESPACE, priority)
        wrapper     = Callback.wrap_function(value)
        data.SO     = true
    end
    P.callback_id_to_table[value] = cb_table

    return wrapper
end

--[[
Removes all registered functions in your namespace.

Automatically called when you hotload your mod.
]]
Callback.remove_all = function(NAMESPACE)
    for type_id, t in pairs(callback_functions) do
        t:remove_all(NAMESPACE)
    end
end
run_on_import(Callback.remove_all)

--[[
Returns a CallbackFunction wrapper containing the provided callback function ID.
]]
---@param id number | CallbackFunction The callback function to wrap.
---@return CallbackFunction
Callback.wrap_function = function(id)
    return new_proxy(unwrap(id), metatable_function)
end


-- ========== Static Methods (Type) ==========

--[[
Creates a new custom callback type with the given identifier
if it does not already exist, or returns the existing one if it does.
]]
---@param identifier string The identifier for the custom callback type.
---@return CallbackType
Callback.new = function(NAMESPACE, identifier)
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing custom callback if found
    local callback = Callback.find(identifier, NAMESPACE, true)
    if callback then return callback end

    -- Get next usable ID
    local id = Callback.CUSTOM_START + P.callback_custom_counter
    P.callback_custom_counter = P.callback_custom_counter + 1

    local wrapper = Callback.wrap_type(id)
    callback_custom:set(wrapper, identifier, NAMESPACE, id)
    return wrapper
end

--[[
Searches for the specified callback type and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return CallbackType | nil
Callback.find = function(identifier, namespace, namespace_is_specified)
    return callback_custom:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all callback types in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, CallbackType>
Callback.find_all = function(namespace, namespace_is_specified)
    return callback_custom:get_all(namespace, namespace_is_specified)
end

--[[
Returns a CallbackType wrapper containing the provided callback type.
]]
---@param id number | CallbackType The callback type to wrap.
---@return CallbackType
Callback.wrap_type = function(id)
    return new_proxy(unwrap(id), metatable_type)
end


-- ========== Wrapper Methods (Function) ==========

---@class CallbackFunction
local methods_function = {}

--[[
Removes and returns the function.
]]
---@return function
methods_function.remove = function(self)
    local id = proxy[self]
    local t  = P.callback_id_to_table[id]
    return t:remove(id)
end

--[[
Returns `true` if the function is enabled.
]]
---@return boolean enabled
methods_function.is_enabled = function(self)
    local id   = proxy[self]
    local t    = P.callback_id_to_table[id]
    local data = t.id_lookup[id]
    return data.enabled
end

--[[
Enables/disables the function.
]]
---@param value boolean
methods_function.toggle = function(self, value)
    if type(value) ~= "boolean" then throw("value must be a bool") end
    local id = proxy[self]
    local t  = P.callback_id_to_table[id]
    t:toggle(id, value)
end


-- ========== Wrapper Methods (Type) ==========

---@class CallbackType
local methods_type = {}

--[[
Call all functions registered under this custom callback type; <br>
this should generally only be done by the custom callback creator.
The return value is whatever the most recent return value of a registered function was.
]]
---@param ... any A variable amount of arguments to pass to the registered functions.
---@return any
methods_type.call = function(self, ...)
    local type_id = proxy[self]
    if type_id < Callback.CUSTOM_START then
        throw("Cannot call for vanilla callback types")
    end

    local cb_table = callback_functions[type_id]
    if not cb_table then return end

    local return_value

    -- Call registered functions
    for i = 1, #cb_table do
        local data = cb_table[i]
        if data.enabled then
            local status, out = pcall(data.fn, ...)
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in callback function of type '"..tostring(type_id).."' (ID "..math.floor(data.id)..")\n| "..out)
            else
                -- Return value
                if out then return_value = out end
            end
        end
    end

    return return_value
end

--[[
Returns `true` if there are any enabled functions registered under this callback type. <br>
You can use this as a check before running any logic for {`call` | Callback#call}.
]]
---@return boolean
methods_type.has_any = function(self)
    return callback_functions[proxy[self]].enabled_count > 0
end


-- ========== Metatables ==========

---@class CallbackFunction
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

local mt_name = "CallbackFunction"

W.CallbackFunction = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        local method = methods_function[k]
        if method then return method end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __tostring = function(t)
        return mt_name..": "..get_table_pointer(t)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable_function = W.CallbackFunction

---@class CallbackType
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field namespace string The namespace of the callback type.
---@field identifier string The identifier of the callback type.

local mt_name = "CallbackType"

W.CallbackType = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        local method = methods_type[k]
        if method then return method end

        -- Getter
        ---@type FindTableData
        local data = callback_custom[proxy[t]]
        if data then
            return data[k]
        end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __tostring = function(t)
        return mt_name..": "..get_table_pointer(t)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable_type = W.CallbackType


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local type_id = args[1].value   ---@type number
    local cb_table = callback_functions[type_id]
    if not cb_table then return end

    local _args = args_holders[args_holder_rsp + 1]
    args_holder_rsp = args_holder_rsp + 1
    
    -- Callback types 0 ~ 42
    if type_id < #callback_constants then
        local arg_types = callback_arg_types[type_id]

        local n = #arg_types
        for i = 1, n do
            local arg = args[i + 1].value
            local arg_type = arg_types[i]
            
            -- Wrap as certain wrappers depending on arg type
            -- TODO
            -- if arg then
            --     if     arg_type == "AttackInfo" then arg = AttackInfo.wrap(arg) -- Assuming `arg` is a Struct wrapper
            --     elseif arg_type == "HitInfo"    then arg = HitInfo.wrap(arg)
            --     elseif arg_type == "Equipment"  then arg = Equipment.wrap(arg)
            --     end
            -- end

            -- Packet and Message edge cases (41 - net_message_onReceived)
            -- TODO
            -- if type_id == Callback.NET_MESSAGE_ON_RECEIVED then
            --     if      i == 1 then arg = Packet.wrap(arg)  -- `nil` if packet ID is not in use
            --     elseif  i == 2 then arg = Buffer.wrap(arg)
            --     end
            -- end
            
            _args[i] = arg
        end
        _args[n + 1] = nil

    -- Other callback types
    else
        local n = #args - 1
        for i = 1, n do
            _args[i] = args[i + 1].value
        end
        _args[n + 1] = nil
    end

    -- Call registered functions
    for i = 1, #cb_table do
        local data = cb_table[i]
        if data.enabled then
            local status, out
            if not data.SO then
                status, out = pcall(data.fn, table_unpack(_args))
            else
                status, out = pcall(data.fn, self, other, table_unpack(_args))
            end
            
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in callback function of type '"..tostring(type_id).."' (ID "..math.floor(data.id)..")\n| "..out)
            else
                -- Result modification from return value
                if out then result.value = out end
            end
        end
    end

    args_holder_rsp = args_holder_rsp - 1
end)

-- TODO RAPI custom callbacks


populate_arg_types()