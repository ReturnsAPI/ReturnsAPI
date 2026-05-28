-- ActorSkill

--[[
Not to be confused with @link {Skill | Skill}.
]]
---@class ActorSkillClass
ActorSkill = new_class()
C.ActorSkill = ActorSkill

local proxy = P.proxy
local metatable
local metatable_struct = W.Struct

local getmetatable = debug.getmetatable
local unwrap       = Wrap.unwrap


-- ========== Static Methods ==========

--[[
Returns an ActorSkill wrapper containing the provided `actor_skill` struct.
]]
---@param struct Struct The `actor_skill` struct to wrap.
---@return ActorSkill
ActorSkill.wrap = function(struct)
    return new_proxy(unwrap(struct), metatable)
end


-- ========== Wrapper Methods ==========

---@class ActorSkill
local methods = {}

--[[
Sets the base cooldown of the ActorSkill.
]]
---@param value number The cooldown to set (in frames).
methods.set_cooldown = function(self, value)
    if not value then throw("value is invalid") end
    proxy[self].set_cooldown(value)
end

--[[
Freezes the remaining cooldown of the ActorSkill for one frame.
]]
methods.freeze_cooldown = function(self)
    proxy[self].freeze_cooldown()
end

--[[
Removes the remaining cooldown for the ActorSkill.
]]
methods.cancel_cooldown = function(self)
    proxy[self].cancel_cooldown()
end

--[[
Restarts the cooldown for the ActorSkill and adds <br>
a stock if the Skill's `auto_restock` is `true`.
]]
methods.reset_cooldown = function(self)
    proxy[self].reset_cooldown()
end

--[[
Sets the remaining cooldown of the ActorSkill.
]]
---@param value number The cooldown to set (in frames).
methods.override_cooldown = function(self, value)
    if not value then throw("value is invalid") end
    local stopwatch = self.cooldown_stopwatch   ---@type Array
    gm.stopwatch_stop(stopwatch)
    gm.stopwatch_start(stopwatch, Global._current_frame + value)
end

--[[
Sets the current stock of the ActorSkill.
]]
---@param value number The stock to set.
methods.set_stock = function(self, value)
    if not value then throw("value is invalid") end
    proxy[self].set_stock(value)
end

--[[
Adds (a) stock to the ActorSkill.
]]
---@param value? number The amount of stocks to add. <br>`1` by default.
---@param ignore_max? boolean If `true`, added stocks can go past `max_stock`. <br>`false` by default.
methods.add_stock = function(self, value, ignore_max)
    proxy[self].add_stock(value or 1, ignore_max or false)
end

--[[
Removes (a) stock from the ActorSkill.
]]
---@param value? number The amount of stocks to remove. <br>`1` by default.
methods.remove_stock = function(self, value)
    proxy[self].remove_stock(value or 1)
end


-- ========== Metatables ==========

---@class ActorSkill
---@field value Struct The value being wrapped.
---@field RAPI string The name of this wrapper.

local mt_name = "ActorSkill"

W.ActorSkill = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        if k == "skill" then return Skill.wrap(proxy[t][k]) end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        return proxy[t][k]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "skill"
        or methods[k] then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        proxy[t][k] = v
    end,

    __len = function(t)
        return #proxy[t]
    end,

    __pairs = function(t)
        return metatable_struct.__pairs(t)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.ActorSkill