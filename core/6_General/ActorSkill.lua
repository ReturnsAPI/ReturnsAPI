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



-- ========== Struct Methods ==========

--@section Struct Methods

--[[
**These should be called using `.` instead of `:`**,
since they are methods belonging to the struct and not the wrapper (i.e., they are @link {Script | Script}s).
]]

--@instance
--@name         set_cooldown
--@param        value       | number    | The cooldown to set (in frames).
--@param        slot        | number    | The @link {slot | Skill#slot} to get from.
--[[
Sets the base cooldown of the ActorSkill.
]]


--@instance
--@name         freeze_cooldown
--[[
Freezes the remaining cooldown of the ActorSkill for one frame.
]]


--@instance
--@name         cancel_cooldown
--[[
Removes the remaining cooldown for the ActorSkill.
]]


--@instance
--@name         reset_cooldown
--[[
Restarts the cooldown for the ActorSkill and adds
a stock if the Skill's `auto_restock` is `true`.
]]


--@instance
--@name         override_cooldown
--@param        value       | number    | The cooldown to set (in frames).
--[[
Sets the remaining cooldown of the ActorSkill.
]]


--@instance
--@name         set_stock
--@param        value       | number    | The stock to set.
--[[
Sets the current stock of the ActorSkill.
]]


--@instance
--@name         add_stock
--@param        value       | number    | The amount of stocks to add.
--@param        ignore_max  | bool      | If `true`, added stocks can go past `max_stock`.
--[[
Adds (a) stock to the ActorSkill.
]]


--@instance
--@name         remove_stock
--@param        value       | number    | The amount of stocks to remove.
--[[
Removes (a) stock from the ActorSkill.
]]



-- ========== Metatables ==========

local wrapper_name = "ActorSkill"

make_table_once("metatable_actorskill", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        if k == "skill" then return Skill.wrap(proxy.skill_id) end

        -- Pass to metatable_struct
        return metatable_struct.__index(proxy, k)
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "skill" then
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