-- Buff

local name_rapi = class_name_g2r["class_buff"]
Buff = __class[name_rapi]



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
`value`         |           | *Read-only.* The buff ID being wrapped.
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