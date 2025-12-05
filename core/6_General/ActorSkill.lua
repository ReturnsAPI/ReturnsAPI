-- ActorSkill

--[[
Not to be confused with @link {Skill | Skill}.
]]

ActorSkill = new_class()



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         |           | *Read-only.* The `sol.YYObjectBase*` being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.
`skill`         | Skill     | *Read-only.* The Skill of the ActorSkill.

<br>

TODO add the rest

Property | Type | Description
| - | - | -
`parent`            | Actor     | The parent of the ActorSkill.
`skill_id`          | number    | The ID of the Skill of the ActorSkill.
`slot_index`        | number    | The @link {skill slot | Skill#Slot} this ActorSkill is in.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       ActorSkill
--@param        actor_skill | Struct    | The `actor_skill` struct to wrap.
--[[
Returns an ActorSkill wrapper containing the provided `actor_skill` struct.
]]
ActorSkill.wrap = function(actor_skill)
    -- Input:   struct or ActorSkill wrapper
    -- Wraps:   struct
    return make_proxy(Wrap.unwrap(actor_skill), metatable_actorskill)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_actorskill = {

    --@instance
    --@param        value       | number    | The cooldown to set (in frames).
    --[[
    Sets the base cooldown of the ActorSkill.
    ]]
    set_cooldown = function(self, value)
        if not value then log.error("set_cooldown: value is invalid", 2) end

        metatable_struct.__index(self, "set_cooldown")
        (
            value
        )
    end,


    --@instance
    --[[
    Freezes the remaining cooldown of the ActorSkill for one frame.
    ]]
    freeze_cooldown = function(self)
        metatable_struct.__index(self, "freeze_cooldown")
        ()
    end,


    --@instance
    --[[
    Removes the remaining cooldown for the ActorSkill.
    ]]
    cancel_cooldown = function(self)
        metatable_struct.__index(self, "cancel_cooldown")
        ()
    end,


    --@instance
    --[[
    Restarts the cooldown for the ActorSkill and adds
    a stock if the Skill's `auto_restock` is `true`.
    ]]
    reset_cooldown = function(self)
        Util.print(metatable_struct.__index(self, "reset_cooldown"))

        metatable_struct.__index(self, "reset_cooldown")
        ()
    end,


    --@instance
    --@param        value       | number    | The cooldown to set (in frames).
    --[[
    Sets the remaining cooldown of the ActorSkill.
    ]]
    override_cooldown = function(self, value)
        if not value then log.error("override_cooldown: value is invalid", 2) end

        local stopwatch = self.cooldown_stopwatch.value
        gm.stopwatch_stop(stopwatch)
        gm.stopwatch_start(stopwatch, Global._current_frame + value)
    end,


    --@instance
    --@param        value       | number    | The stock to set.
    --[[
    Sets the current stock of the ActorSkill.
    ]]
    set_stock = function(self, value)
        if not value then log.error("set_stock: value is invalid", 2) end

        metatable_struct.__index(self, "set_stock")
        (
            value
        )
    end,


    --@instance
    --@param        value       | number    | The amount of stocks to add. <br>`1` by default.
    --@param        ignore_max  | bool      | If `true`, added stocks can go past `max_stock`. <br>`false` by default.
    --[[
    Adds (a) stock to the ActorSkill.
    ]]
    add_stock = function(self, value, ignore_max)
        metatable_struct.__index(self, "add_stock")
        (
            value       or 1,
            ignore_max  or false
        )
    end,


    --@instance
    --@param        value       | number    | The amount of stocks to remove. <br>`1` by default.
    --[[
    Removes (a) stock from the ActorSkill.
    ]]
    remove_stock = function(self, value)
        metatable_struct.__index(self, "remove_stock")
        (
            value or 1
        )
    end,

}



-- ========== Metatables ==========

local wrapper_name = "ActorSkill"

make_table_once("metatable_actorskill", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        if k == "skill" then return Skill.wrap(proxy.skill_id) end

        -- Methods
        if methods_actorskill[k] then
            return methods_actorskill[k]
        end

        -- Pass to metatable_struct
        return metatable_struct.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "skill"
        or methods_actorskill[k] then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Pass to metatable_struct
        return metatable_struct.__newindex(proxy, k, v)
    end,


    __len = function(proxy)
        return metatable_struct.__len(proxy)
    end,


    __pairs = function(proxy)
        return metatable_struct.__pairs(proxy)
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



__class.ActorSkill = ActorSkill