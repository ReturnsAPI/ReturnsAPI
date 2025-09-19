-- Buff

local name_rapi = class_name_g2r["class_buff"]
Buff = __class[name_rapi]

run_once(function()
    __actors_holding_buff = {}
end)



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
SHOW_ICON               2
ICON_SPRITE             3
ICON_SUBIMAGE           4
ICON_FRAME_SPEED        5
ICON_STACK_SUBIMAGE     6
DRAW_STACK_NUMBER       7
STACK_NUMBER_COL        8
MAX_STACK               9
ON_APPLY                10
ON_REMOVE               11
ON_STEP                 12
IS_TIMED                13
IS_DEBUFF               14
CLIENT_HANDLES_REMOVAL  15
EFFECT_DISPLAY          16
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The buff ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the buff is in.
`identifier`                | string    | The identifier for the buff within the namespace.
`show_icon`                 | bool      | `true` if the icon should be shown.
`icon_sprite`               | sprite    | 
`icon_subimage`             | number    | 
`icon_frame_speed`          | number    | 
`icon_stack_subimage`       | number    | 
`draw_stack_number`         | bool      | `true` if the buff stack count should be displayed beside the icon.
`stack_number_col`          | Array     | 
`max_stack`                 | number    | The maximum number of stacks.
`on_apply`                  | number    | The ID of the callback that runs when the buff is applied.
`on_remove`                 | number    | The ID of the callback that runs when the buff is removed.
`on_step`                   | number    | The ID of the callback that runs every frame.
`is_timed`                  | bool      | 
`is_debuff`                 | bool      | `true` if the buff is considered a debuff.
`client_handles_removal`    | bool      | 
`effect_display`            |           | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Buff
--@param    identifier  | string    | The identifier for the buff.
--[[
Creates a new buff with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Buff.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started()
    if not identifier then log.error("No identifier provided", 2) end

    -- Return existing buff if found
    local buff = Buff.find(identifier, NAMESPACE)
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



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the buff's properties.
    ]]


    --@instance
    --[[
    Returns a table of all actors that currently hold at least 1 stack of the buff.
    ]]
    get_holding_actors = function(self)
        local t = {}

        for actor_id, _ in pairs(__actors_holding_buff[self.value]) do
            table.insert(t, Instance.wrap(actor_id))
        end

        return t
    end

})



-- ========== Hooks ==========

-- Extend buff_stack to accommodate custom buffs
-- The game does *not* automatically do this

gm.post_script_hook(gm.constants.init_actor_default, function(self, other, result, args)
    -- Get actor `buff_stack`
    local array = gm.variable_instance_get(self, "buff_stack")
    if array then
        -- Resize to match global `count_buff`
        gm.array_resize(array, Global.count_buff)
    end
end)


-- Create buff subtable in `__actors_holding_buff`

gm.post_script_hook(gm.constants.buff_create, function(self, other, result, args)
    local buff_id = result.value
    local buff = Buff.wrap(buff_id)

    __actors_holding_buff[buff_id] = {}

    -- Add an `on_remove` callback to reset the
    -- cached value for that buff of the actor
    -- * This callback should never be removed, hence the namespace
    --      This is because buff_create will never run more than once
    --      for a buff, so if it is removed it cannot be readded
    Callback.add("__permanent", buff.on_remove, function(actor)
        
        -- Feels a little messy, but this callback runs before
        -- the buff is removed, so `buff_count` will never be 0
        -- Shouldn't be a real problem though
        Alarm.new(_ENV["!guid"], 1, function()
            local actor_id  = actor.id

            if actor:buff_count(buff_id) > 0 then return end

            __actors_holding_buff[buff_id][actor_id] = nil
            if __actors_holding_buff[actor_id] then
                __actors_holding_buff[actor_id][buff_id] = nil
            end
        end, actor)
    end, 1000000000)    -- Make sure this runs first
end)


-- Add to `__actors_holding_buff`

gm.post_script_hook(gm.constants.apply_buff_internal, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    local buff_id   = args[2].value

    __actors_holding_buff[buff_id][actor_id] = true
    __actors_holding_buff[actor_id] = __actors_holding_buff[actor_id] or {}
    __actors_holding_buff[actor_id][buff_id] = true
end)


-- On room change, remove non-existent instances from `__actors_holding_buff`

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    for actor_id, _ in pairs(__actors_holding_buff) do
        if actor_id >= 100000
        and (not Instance.exists(actor_id)) then
            for buff_id, _ in pairs(__actors_holding_buff[actor_id]) do
                __actors_holding_buff[buff_id][actor_id] = nil
            end
            __actors_holding_buff[actor_id] = nil
        end
    end
end)


-- Remove from `__actors_holding_buff` on non-player kill

gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    local actor_id = Instance.wrap(args[1].value).id
    if not __actors_holding_buff[actor_id] then return end

    -- Do not clear for player deaths
    local obj_ind = gm.variable_instance_get(actor_id, "object_index")
    if obj_ind ~= gm.constants.oP then
        for buff_id, _ in pairs(__actors_holding_buff[actor_id]) do
            __actors_holding_buff[buff_id][actor_id] = nil
        end
        __actors_holding_buff[actor_id] = nil
    end
end)


-- Add new instance to `__actors_holding_buff` and remove old

gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    local new_id    = Instance.wrap(args[2].value).id

    __actors_holding_buff[new_id] = __actors_holding_buff[new_id] or {}

    -- For all of prev actor's buffs, remove prev actor and add new actor
    for buff_id, _ in pairs(__actors_holding_buff[actor_id]) do
        __actors_holding_buff[buff_id][actor_id] = nil
        __actors_holding_buff[buff_id][new_id] = true
        __actors_holding_buff[new_id][buff_id] = true
    end
    __actors_holding_buff[actor_id] = nil
end)