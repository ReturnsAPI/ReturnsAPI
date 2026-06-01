-- Skill

---@class SkillClass
Skill = C["Skill"]

run_on_initial_load(function()
    P.skill_on_step_callbacks = {}  ---@type table<number, SkillOnStepData> Maps skill IDs to data on their `on_step` callbacks.
end)

local skill_on_step_callbacks = P.skill_on_step_callbacks
local callback_functions      = P.callback_functions

local proxy              = P.proxy
local metatable          = W["Skill"]
local find_table_wrapper = P.class_find_tables_wrapper["Skill"]
local find_table_array   = P.class_find_tables_array["Skill"]

local pcall              = pcall
local table_insert       = table.insert
local table_remove       = table.remove
local table_remove_value = table.remove_value
local table_find         = table.find
local table_find_array   = table.find_array
local table_find_sorted  = table.find_sorted_array
local Instance           = Instance
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Skill
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this skill's properties.
---@field array Array Alias for .properties.

---@class Skill
---@field namespace                   string  The namespace the skill is in.
---@field identifier                  string  The identifier for the skill within the namespace.
---@field token_name                  string  
---@field token_description           string  
---@field sprite                      number  
---@field subimage                    number  
---@field cooldown                    number  The base cooldown of the skill (in frames).
---@field damage                      number  The damage of the skill; 1 is 100% damage. <br>Does nothing if the skill/states themselves do not refer to it. <br>Can also be gotten using GM.skill_get_damage( skill ).
---@field max_stock                   number  
---@field start_with_stock            boolean If true, this skill will start with max_stock instead of 0.
---@field auto_restock                unknown 
---@field required_stock              unknown 
---@field require_key_press           boolean 
---@field allow_buffered_input        unknown 
---@field use_delay                   unknown 
---@field animation                   unknown 
---@field is_utility                  boolean 
---@field is_primary                  boolean 
---@field required_interrupt_priority unknown 
---@field hold_facing_direction       unknown 
---@field override_strafe_direction   unknown 
---@field ignore_aim_direction        boolean 
---@field disable_aim_stall           boolean 
---@field does_change_activity_state  unknown 
---@field on_can_activate             number  The ID of the callback that runs when . <br>The callback function should have the arguments (TODO).
---@field on_activate                 number  The ID of the callback that runs when the skill is used. <br>The callback function should have the arguments `actor, skill, slot`.
---@field on_step                     number  The ID of the callback that runs every frame while slotted. <br>The callback function should have the arguments `actor, skill, slot`.
---@field on_equipped                 number  The ID of the callback that runs when the skill is slotted. <br>The callback function should have the arguments `actor, skill, slot`.
---@field on_unequipped               number  The ID of the callback that runs when the skill is unslotted. <br>The callback function should have the arguments `actor, skill, slot`.
---@field upgrade_skill               number  The ID of the skill to upgrade to when picking up Ancient Scepter.


-- ========== Enums ==========

Skill.Property = {
    NAMESPACE                   = 0,
    IDENTIFIER                  = 1,
    TOKEN_NAME                  = 2,
    TOKEN_DESCRIPTION           = 3,
    SPRITE                      = 4,
    SUBIMAGE                    = 5,
    COOLDOWN                    = 6,
    DAMAGE                      = 7,
    MAX_STOCK                   = 8,
    START_WITH_STOCK            = 9,
    AUTO_RESTOCK                = 10,
    REQUIRED_STOCK              = 11,
    REQUIRE_KEY_PRESS           = 12,
    ALLOW_BUFFERED_INPUT        = 13,
    USE_DELAY                   = 14,
    ANIMATION                   = 15,
    IS_UTILITY                  = 16,
    IS_PRIMARY                  = 17,
    REQUIRED_INTERRUPT_PRIORITY = 18,
    HOLD_FACING_DIRECTION       = 19,
    OVERRIDE_STRAFE_DIRECTION   = 20,
    IGNORE_AIM_DIRECTION        = 21,
    DISABLE_AIM_STALL           = 22,
    DOES_CHANGE_ACTIVITY_STATE  = 23,
    ON_CAN_ACTIVATE             = 24,
    ON_ACTIVATE                 = 25,
    ON_STEP                     = 26,
    ON_EQUIPPED                 = 27,
    ON_UNEQUIPPED               = 28,
    UPGRADE_SKILL               = 29,
}
local t = {}
for name, num in pairs(Skill.Property) do t[num] = name end
for i = 0, #t do Skill.Property[i] = t[i] end

Skill.Slot = {
    PRIMARY   = 0,
    SECONDARY = 1,
    UTILITY   = 2,
    SPECIAL   = 3,
}

Skill.OverridePriority = {
    UPGRADE = 0,
    BOOSTED = 1,
    RELOAD  = 2,
    CANCEL  = 3,
}


-- ========== Static Methods ==========

--[[
Creates a new skill with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the skill.
---@return Skill
Skill.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing skill if found
    local skill = Skill.find(identifier, NAMESPACE, true)
    if skill then return skill end

    -- Create new
    skill = Skill.wrap(gm.skill_create(
        NAMESPACE,
        identifier
    ))

    return skill
end

--[[
Searches for the specified skill and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Skill
Skill.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all skill in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>Skill.Property.NAMESPACE by default.
---@return table<number, Skill>
Skill.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a skill wrapper containing the provided skill ID.
]]
---@param id number | Skill The skill to wrap.
---@return Skill
Skill.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Skill
local methods = G.methods_content["Skill"]

--[[
Returns the associated @link {Achievement | Achievement} if it exists, <br>
or an invalid Achievement if it does not.
]]
---@return Achievement
methods.get_achievement = function(self)
    return Achievement.wrap(G.skill_achievement_map[proxy[self]] or -1)
end

--[[
Prints the skill's properties.
]]
methods.print = function(self) end


-- ========== Hooks ==========

-- Allow Skill `on_step` callbacks to run
gm.post_script_hook(gm.constants.skill_create, function(self, other, result, args)
    local on_step_id = Global.class_skill:get(result.value):get(Skill.Property.ON_STEP)
    
    ---@class SkillOnStepData
    ---@field [1] CallbackType
    ---@field [2] table<i, actor_id> List of actors to iterate over.
    ---@field [3] table<actor_id, table<i, slot>> Mapping of actor IDs to skill slots.
    skill_on_step_callbacks[result.value] = {
        Callback.wrap_type(on_step_id),
        {},
        {},
    }

    -- OLD callback_execute impl
    -- skill_on_step_callbacks[result.value] = {
    --     Callback.wrap_type(on_step_id),
    --     false,
    -- }
end)

gm.post_script_hook(gm.constants["update_active_skill@anon@4242@ActorSkillSlot@scr_actor_skills"], function(self, other, result, args)
    local skill   = self.active_skill.skill_id
    local on_step = skill_on_step_callbacks[skill]
    if not on_step then return end

    local parent   = self.parent
    local actor_id = parent.id
    local actors   = on_step[2]      ---@type table<i, actor_id>
    local slots    = on_step[3]      ---@type table<actor_id, table<i, slot>>
    local t_slots  = slots[actor_id] ---@type table<i, slot>
    if not t_slots then
        table_insert(actors, actor_id)
        t_slots = {}
        slots[actor_id] = t_slots
    end
    
    local slot = self.slot_index
    if not table_find_array(t_slots, slot) then
        table_insert(t_slots, slot)
    end

    -- Add Destroy event hook to remove from `skill_on_step_callbacks`
    if parent:get_object_index() == gm.constants.oP then return end
    if gm.event_hook_pre_has(parent, gm.constants.ev_destroy, 0, "skill_on_step_callbacks_remove") then return end
    gm.event_hook_pre_add(parent, gm.constants.ev_destroy, 0, "skill_on_step_callbacks_remove", function(inst)
        for skill, on_step in pairs(skill_on_step_callbacks) do
            local actors = on_step[2]  ---@type table<i, actor_id>
            local slots  = on_step[3]  ---@type table<actor_id, table<i, slot>>
            table_remove_value(actors, actor_id)
            slots[actor_id] = nil
        end
    end)
end)

Callback.add(RAPI_NAMESPACE, Callback.ON_STEP, Callback.internal.FIRST, function()
    for skill_id, on_step in pairs(skill_on_step_callbacks) do
        local cb_type = on_step[1]
        if cb_type:has_any() then
            local type_id  = proxy[cb_type]
            local cb_table = callback_functions[type_id]
            if not cb_table then return end

            local actors = on_step[2]  ---@type table<i, actor_id>
            for j = 1, #actors do
                local actor_id = actors[j]
                local actor    = Instance.wrap(actor_id)

                -- Loop through slots
                local slots = on_step[3][actor_id]  ---@type table<i, slot>
                for i = 1, #slots do
                    local slot = slots[i]

                    -- Call registered functions
                    for i = 1, #cb_table do
                        local data = cb_table[i]
                        if data.enabled then
                            local status, out = pcall(data.fn, actor, skill_id, slot)  -- TODO wrap `skill`?
                            if not status then
                                if out == nil
                                or out == "C++ exception" then
                                    out = "GameMaker error (see above)"
                                end
                                log.warning("\n| "..data.namespace..": Error in callback function of type '"..tostring(type_id).."' (ID "..math.floor(data.id)..")\n| "..out)
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- On room change, remove non-existent actors from `skill_on_step_callbacks`
Hook.add_post(RAPI_NAMESPACE, gm.constants.room_goto, Callback.internal.FIRST, function(self, other, result, args)
    for skill, on_step in pairs(skill_on_step_callbacks) do
        local actors = on_step[2]  ---@type table<i, actor_id>
        local slots  = on_step[3]  ---@type table<actor_id, table<i, slot>>
        for i = #actors, 1, -1 do
            local actor_id = actors[i]
            if not Instance.exists(actor_id) then
                table_remove(actors, i)
                slots[actor_id] = nil
            end
        end
    end
end)

-- Remove from `skill_on_step_callbacks` on non-player kill
-- Hook.add_post(RAPI_NAMESPACE, gm.constants.actor_set_dead, Callback.internal.FIRST, function(self, other, result, args)
--     local actor_id = args[1].value.id
--     local obj_ind  = Instance.wrap(actor_id):get_object_index()
--     if obj_ind == gm.constants.oP then return end

--     for skill, on_step in pairs(skill_on_step_callbacks) do
--         local actors = on_step[2]  ---@type table<i, actor_id>
--         local slots  = on_step[3]  ---@type table<actor_id, table<i, slot>>
--         table_remove_value(actors, actor_id)
--         slots[actor_id] = nil
--     end
-- end)

-- Remove from `skill_on_step_callbacks` on transform
-- Hook.add_post(RAPI_NAMESPACE, gm.constants.actor_transform, Callback.internal.FIRST, function(self, other, result, args)
--     local actor_id = args[1].value.id

--     for skill, on_step in pairs(skill_on_step_callbacks) do
--         local actors = on_step[2]  ---@type table<i, actor_id>
--         local slots  = on_step[3]  ---@type table<actor_id, table<i, slot>>
--         table_remove_value(actors, actor_id)
--         slots[actor_id] = nil
--     end
-- end)

-- OLD callback_execute impl
-- Hook.add_post(RAPI_NAMESPACE, gm.constants.__input_system_tick, Callback.internal.FIRST, function(self, other, result, args)    
--     for skill, on_step in pairs(skill_on_step_callbacks) do
--         local cb_type = on_step[1]

--         -- Enable callback type if any fns are present
--         if cb_type:has_any() and (not on_step[2]) then
--             local value = proxy[cb_type]
--             Global.class_callback:get(value):set(1, true)
--             on_step[2] = true

--         -- Disable callback type if no fns are present
--         elseif (not cb_type:has_any()) and on_step[2] then
--             local value = proxy[cb_type]
--             Global.class_callback:get(value):set(1, false)
--             on_step[2] = false
--         end
--     end
-- end)