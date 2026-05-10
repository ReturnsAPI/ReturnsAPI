-- Callback

---@class Callback
Callback = new_class()
C.Callback = Callback

run_on_initial_load(function()
    P.callback_functions      = {}  ---@type table<integer, CallbackTable>
    P.callback_counter        = {value = 0} -- Shared counter for all callback `CallbackTable`s.
    P.callback_id_to_table    = {}  ---@type table<integer, CallbackTable> Stores which CallbackTable a function is in.
    
    P.callback_custom_counter = 0   -- Next usable custom callback ID; `Callback.CUSTOM_START` is added to this.
end)

local callback_arg_types = {}   ---@type table<integer, table<integer, string>> Contains argument types for callbacks `0` to `42`.

local proxy = P.proxy
local metatable_type
local metatable_function
local callback_functions = P.callback_functions

local type         = type
local new_proxy    = new_proxy
local table_unpack = table.unpack
local wrap         = Wrap.wrap
local unwrap       = Wrap.unwrap

local args_holders = {}     -- Reusable tables for arg holders
local args_holder_rsp = 0   -- Index of most recently used; increment before taking
for i = 1, 128 do args_holders[i] = {} end


-- ========== Constants and Enums ==========

---@class Callback
---@field ON_LOAD                            0
---@field POST_LOAD                          1
---@field ON_STEP                            2
---@field PRE_STEP                           3
---@field POST_STEP                          4
---@field ON_DRAW                            5
---@field PRE_HUD_DRAW                       6
---@field ON_HUD_DRAW                        7
---@field POST_HUD_DRAW                      8
---@field CAMERA_ON_VIEW_CAMERA_UPDATE       9
---@field ON_SCREEN_REFRESH                  10
---@field ON_GAME_START                      11
---@field ON_GAME_END                        12
---@field ON_DIRECTOR_POPULATE_SPAWN_ARRAYS  13
---@field ON_STAGE_START                     14
---@field ON_SECOND                          15
---@field ON_MINUTE                          16
---@field ON_ATTACK_CREATE                   17
---@field ON_ATTACK_HIT                      18
---@field ON_ATTACK_HANDLE_START             19
---@field ON_ATTACK_HANDLE_END               20
---@field ON_DAMAGE_BLOCKED                  21
---@field ON_ENEMY_INIT                      22
---@field ON_ELITE_INIT                      23
---@field ON_DEATH                           24
---@field ON_PLAYER_INIT                     25
---@field ON_PLAYER_STEP                     26
---@field PRE_PLAYER_HUD_DRAW                27
---@field ON_PLAYER_HUD_DRAW                 28
---@field ON_PLAYER_INVENTORY_UPDATE         29
---@field ON_PLAYER_DEATH                    30
---@field ON_CHECKPOINT_RESPAWN              31
---@field ON_INPUT_PLAYER_DEVICE_UPDATE      32
---@field ON_PICKUP_COLLECTED                33
---@field ON_PICKUP_ROLL                     34
---@field ON_EQUIPMENT_USE                   35
---@field POST_EQUIPMENT_USE                 36
---@field ON_INTERACTABLE_ACTIVATE           37
---@field ON_HIT_PROC                        38
---@field ON_DAMAGED_PROC                    39
---@field ON_KILL_PROC                       40
---@field NET_MESSAGE_ON_RECEIVED            41
---@field CONSOLE_ON_COMMAND                 42

local callback_constants = {
    "ON_LOAD", "POST_LOAD", "ON_STEP", "PRE_STEP", "POST_STEP",
    "ON_DRAW", "PRE_HUD_DRAW", "ON_HUD_DRAW", "POST_HUD_DRAW", "CAMERA_ON_VIEW_CAMERA_UPDATE",
    "ON_SCREEN_REFRESH", "ON_GAME_START", "ON_GAME_END", "ON_DIRECTOR_POPULATE_SPAWN_ARRAYS",
    "ON_STAGE_START", "ON_SECOND", "ON_MINUTE", "ON_ATTACK_CREATE", "ON_ATTACK_HIT", "ON_ATTACK_HANDLE_START",
    "ON_ATTACK_HANDLE_END", "ON_DAMAGE_BLOCKED", "ON_ENEMY_INIT", "ON_ELITE_INIT", "ON_DEATH", "ON_PLAYER_INIT", "ON_PLAYER_STEP",
    "PRE_PLAYER_HUD_DRAW", "ON_PLAYER_HUD_DRAW", "ON_PLAYER_INVENTORY_UPDATE", "ON_PLAYER_DEATH",
    "ON_CHECKPOINT_RESPAWN", "ON_INPUT_PLAYER_DEVICE_UPDATE", "ON_PICKUP_COLLECTED", "ON_PICKUP_ROLL", "ON_EQUIPMENT_USE", "POST_EQUIPMENT_USE", "ON_INTERACTABLE_ACTIVATE",
    "ON_HIT_PROC", "ON_DAMAGED_PROC", "ON_KILL_PROC",
    "NET_MESSAGE_ON_RECEIVED", "CONSOLE_ON_COMMAND"
}
for type_id, name in ipairs(callback_constants) do
    Callback[name] = type_id - 1
end

-- Custom callbacks

Callback.CUSTOM_START = 10000

Callback.ON_HEAL           = 10000
Callback.ON_SHIELD_BREAK   = 10001
Callback.ON_SHIELD_RESTORE = 10002
Callback.ON_SKILL_ACTIVATE = 10003
Callback.ON_EQUIPMENT_SWAP = 10004

Callback.Priority = {
    NORMAL = 0,
    BEFORE = 1000,
    AFTER  = -1000
}
Callback.internal.FIRST = math.huge


-- ========== Private Methods ==========

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
        
        -- TODO

        -- Populate find cache with vanilla callbacks
        -- local identifier = name:lower()
        -- while true do
        --     local pos = identifier:find("_")
        --     if not pos then break end

        --     -- E.g., ON_STAGE_START -> onStageStart
        --     identifier = identifier:sub(1, pos - 1)..identifier:sub(pos + 1, pos + 1):upper()..identifier:sub(pos + 2, -1)
        -- end

        -- __callback_find_cache:set(
        --     {
        --         wrapper = Callback.wrap_type(type_id - 1),
        --     },
        --     identifier,
        --     "ror",
        --     type_id - 1
        -- )
    end
end


-- ========== Static Methods ==========

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
]]
---@param callback number | CallbackType The callback type to register under.
---@param priority integer The priority of the function. <br>Higher values run before lower ones. <br>`0` by default.
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

-- TODO add_SO

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

-- TODO find for custom

--[[
Returns a CallbackType wrapper containing the provided callback type.
]]
---@param id CallbackType | integer The callback type to wrap.
---@return CallbackType
Callback.wrap_type = function(id)
    return new_proxy(unwrap(id), metatable_type)
end

--[[
Returns a CallbackFunction wrapper containing the provided callback function ID.
]]
---@param id CallbackFunction | integer The callback function to wrap.
---@return CallbackFunction
Callback.wrap_function = function(id)
    return new_proxy(unwrap(id), metatable_function)
end

-- TODO Callback.new


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


-- ========== Metatables ==========

---@class CallbackType
---@field value integer
---@field RAPI string

local mt_name = "CallbackType"

W.CallbackType = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        if methods_type[k] then return methods_type[k] end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable_type = W.CallbackType

---@class CallbackFunction
---@field value integer
---@field RAPI string

local mt_name = "CallbackFunction"

W.CallbackFunction = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        
        -- Methods
        if methods_function[k] then return methods_function[k] end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable_function = W.CallbackFunction


-- ========== Hooks ==========

---@type table<string, true>
local instance = table.set{
    "Instance_pActor",
    "Instance_oP",
    "Instance_pPickup",
    "Instance_pInteractable",
}

gm.post_script_hook(gm.constants.callback_execute, function(self, other, result, args)
    local type_id = args[1].value   ---@type integer
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
            --     if     instance[arg_type] and arg == -4 then arg = Instance.INVALID     -- Wrap as invalid Instance if -4
            --     elseif arg_type == "AttackInfo"         then arg = AttackInfo.wrap(arg) -- Assuming `arg` is a Struct wrapper
            --     elseif arg_type == "HitInfo"            then arg = HitInfo.wrap(arg)
            --     elseif arg_type == "Equipment"          then arg = Equipment.wrap(arg)
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
            local status, out = pcall(data.fn, table_unpack(_args))
            if not status then
                if out == nil
                or out == "C++ exception" then
                    out = "GameMaker error (see above)"
                end
                log.warning("\n| "..data.namespace..": Error in callback function of type '"..tostring(type_id).."' (ID "..math.floor(data.id)..")\n| "..out)
            end

            -- Result modification from return value
            if out then
                result.value = unwrap(out)
            end
        end
    end

    args_holder_rsp = args_holder_rsp - 1
end)


populate_arg_types()