-- Buff

---@class BuffClass
Buff = C["Buff"]

run_on_initial_load(function()
    P.actors_holding_buff = {} ---@type table<actor_id | buff_id, table<buff_id | actor_id, true>> Mappings: <br>`table[actor_id][buff_id] = true` <br>`table[buff_id][actor_id] = true`
end)

local actors_holding_buff = P.actors_holding_buff

local proxy              = P.proxy
local metatable          = W["Buff"]
local find_table_wrapper = P.class_find_tables_wrapper["Buff"]
local find_table_array   = P.class_find_tables_array["Buff"]

local gm                 = gm  ---@type table<string, function>
local Global             = Global
local Instance           = Instance
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Buff
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this buff's properties.
---@field array Array Alias for `.properties`.

---@class Buff
---@field namespace              string        The namespace the buff is in.
---@field identifier             string        The identifier for the buff within the namespace.
---@field show_icon              boolean       `true` if the icon should be shown. <br>`true` by default.
---@field icon_sprite            number        
---@field icon_subimage          number        
---@field icon_frame_speed       number        
---@field icon_stack_subimage    boolean        
---@field draw_stack_number      boolean       `true` if the buff stack count should be displayed beside the icon. <br>`false` by default.
---@field stack_number_col       Array         An array of colors to use for the drawn stack count. <br>`Array.new(1, Color.WHITE)` by default.
---@field max_stack              number        The maximum number of stacks. <br>`1` by default.
---@field on_apply               number        The ID of the callback that runs when the buff is applied. <br>The callback function should have the argument `actor`.
---@field on_remove              number        The ID of the callback that runs when the buff is *fully* removed. <br>The callback function should have the argument `actor`.
---@field on_step                number        The ID of the callback that runs every frame while having the buff. <br>The callback function should have the argument `actor`.
---@field is_timed               boolean       <br>`true` by default.
---@field is_debuff              boolean       `true` if the buff is considered a debuff. <br>`true` by default.
---@field client_handles_removal boolean       <br>`false` by default.
---@field effect_display         EffectDisplay 

-- ========== Enums ==========

Buff.Property = {
    NAMESPACE              = 0,
    IDENTIFIER             = 1,
    SHOW_ICON              = 2,
    ICON_SPRITE            = 3,
    ICON_SUBIMAGE          = 4,
    ICON_FRAME_SPEED       = 5,
    ICON_STACK_SUBIMAGE    = 6,
    DRAW_STACK_NUMBER      = 7,
    STACK_NUMBER_COL       = 8,
    MAX_STACK              = 9,
    ON_APPLY               = 10,
    ON_REMOVE              = 11,
    ON_STEP                = 12,
    IS_TIMED               = 13,
    IS_DEBUFF              = 14,
    CLIENT_HANDLES_REMOVAL = 15,
    EFFECT_DISPLAY         = 16,
}
local t = {}
for name, num in pairs(Buff.Property) do t[num] = name end
for i = 0, #t do Buff.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new buff with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the buff.
---@return Buff
Buff.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing buff if found
    local buff = Buff.find(identifier, NAMESPACE, true)
    if buff then return buff end

    -- Create new
    buff = Buff.wrap(gm.buff_create(
        NAMESPACE,
        identifier
    ))

    -- Set default `stack_number_col` to pure white
    buff.stack_number_col = Array.new(1, Color.WHITE)

    return buff
end

--[[
Searches for the specified buff and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Buff
Buff.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all buff in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`Buff.Property.NAMESPACE` by default.
---@return table<number, Buff>
Buff.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a buff wrapper containing the provided buff ID.
]]
---@param id number | Buff The buff to wrap.
---@return Buff
Buff.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Buff
local methods = G.methods_content["Buff"]

--[[
Returns a table of all actors that currently hold at least 1 stack of the buff.
]]
---@return table<number, Actor>
methods.get_holding_actors = function(self)
    if Global.pause and not Net.online then return {} end

    local t, i = {}, 1
    for actor_id, _ in pairs(actors_holding_buff[proxy[self]]) do
        t[i] = Instance.wrap(actor_id)
        i = i + 1
    end
    return t
end

--[[
Prints the buff's properties.
]]
methods.print = function(self) end


-- ========== Hooks ==========

-- Extend `buff_stack` to accommodate custom buffs
-- The game does *not* automatically do this
gm.post_script_hook(gm.constants.init_actor_default, function(self, other, result, args)
    -- Resize actor `buff_stack` to match global `count_buff`
    local array = self.buff_stack
    if array then
        gm.array_resize(array, Global.count_buff)
    end
end)

-- Create buff subtable in `actors_holding_buff`
gm.post_script_hook(gm.constants.buff_create, function(self, other, result, args)
    local buff_id = result.value
    local buff    = Buff.wrap(buff_id)

    local t_buff = {}
    actors_holding_buff[buff_id] = t_buff

    -- Add an `on_remove` callback to reset the
    -- cached value for that buff of the actor
    -- * This callback should never be removed, hence the namespace
    --      This is because buff_create will never run more than once
    --      for a buff, so if it is removed it cannot be readded
    Callback.add(PERMANENT_NAMESPACE, buff.on_remove, Callback.internal.FIRST, function(actor)
        
        -- Since this callback runs before the buff is removed,
        -- `buff_count` will never be 0, so the cache reset needs
        -- to be delayed by 1 frame to work properly
        -- Feels a little messy but shouldn't be a real problem
        Alarm.add(RAPI_NAMESPACE, 1, function()
            local actor_id = actor.id

            if actor:buff_count(buff_id) > 0 then return end

            t_buff[actor_id] = nil
            local t_actor = actors_holding_buff[actor_id]
            if t_actor then
                t_actor[buff_id] = nil
            end
        end, actor)
    end)
end)

-- Add to `actors_holding_buff`
gm.post_script_hook(gm.constants.apply_buff_internal, function(self, other, result, args)
    local actor_id = args[1].value.id
    local buff_id  = args[2].value

    actors_holding_buff[buff_id][actor_id] = true
    local t_actor = actors_holding_buff[actor_id]
    if not t_actor then
        t_actor = {}
        actors_holding_buff[actor_id] = t_actor
    end
    t_actor[buff_id] = true

    if gm.event_hook_pre_has(args[1].value, gm.constants.ev_destroy, 0, "actors_holding_buff_destroy") then return end
    gm.event_hook_pre_add(args[1].value, gm.constants.ev_destroy, 0, "actors_holding_buff_destroy", function(inst)
        local t_actor = actors_holding_buff[actor_id]
        if not t_actor then return end
        for buff_id, _ in pairs(t_actor) do
            actors_holding_buff[buff_id][actor_id] = nil
        end
        actors_holding_buff[actor_id] = nil
    end)
end)

-- On room change, remove non-existent instances from `actors_holding_buff`
Hook.add_post(RAPI_NAMESPACE, gm.constants.room_goto, Callback.internal.FIRST, function(self, other, result, args)
    for actor_id, _ in pairs(actors_holding_buff) do
        if actor_id >= 100000  -- Make sure this is an actor and not an item
        and not Instance.exists(actor_id) then
            for buff_id, _ in pairs(actors_holding_buff[actor_id]) do
                actors_holding_buff[buff_id][actor_id] = nil
            end
            actors_holding_buff[actor_id] = nil
        end
    end
end)

-- Remove from `actors_holding_buff` on non-player kill
Hook.add_post(RAPI_NAMESPACE, gm.constants.actor_set_dead, Callback.internal.FIRST, function(self, other, result, args)
    local actor    = Instance.wrap(args[1].value)
    local actor_id = actor.id
    local t_actor  = actors_holding_buff[actor_id]
    if not t_actor then return end

    -- Do not clear for player deaths
    local obj_ind = actor:get_object_index()
    if obj_ind ~= gm.constants.oP then
        for buff_id, _ in pairs(t_actor) do
            actors_holding_buff[buff_id][actor_id] = nil
        end
        actors_holding_buff[actor_id] = nil
    end
end)

-- Add new instance to `actors_holding_buff` and remove old
Hook.add_post(RAPI_NAMESPACE, gm.constants.actor_transform, Callback.internal.FIRST, function(self, other, result, args)
    local actor_id = Instance.wrap(args[1].value).id
    local t_actor  = actors_holding_buff[actor_id]
    if not t_actor then return end

    local new_id = Instance.wrap(args[2].value).id
    local t_new  = actors_holding_buff[new_id]
    if not t_new then
        t_new = {}
        actors_holding_buff[new_id] = t_new
    end

    -- For all of prev actor's buffs, remove prev actor and add new actor
    for buff_id, _ in pairs(t_actor) do
        actors_holding_buff[buff_id][actor_id] = nil
        actors_holding_buff[buff_id][new_id] = true
        t_new[buff_id] = true
    end
    actors_holding_buff[actor_id] = nil
end)

-- Remove instance from `actors_holding_buff` on client disconnect
gm.post_script_hook(gm.constants.disconnect_player, function(self, other, result, args)
    if not Global.__run_exists then return end

    local player_id = args[1].value.id
    local t_actor   = actors_holding_buff[player_id]
    if not t_actor then return end

    for buff_id, _ in pairs(t_actor) do
        actors_holding_buff[buff_id][player_id] = nil
    end
    actors_holding_buff[player_id] = nil
end)