-- Elite

---@class EliteClass
Elite = C["Elite"]

local proxy              = P.proxy
local metatable          = W["Elite"]
local find_table_wrapper = P.class_find_tables_wrapper["Elite"]
local find_table_array   = P.class_find_tables_array["Elite"]

local gm                 = gm  ---@type table<string, function>
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Elite
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this elite's properties.
---@field array Array Alias for .properties.

---@class Elite
---@field namespace      string        The namespace the elite is in.
---@field identifier     string        The identifier for the elite within the namespace.
---@field token_name     string        
---@field palette        sprite        
---@field blend_col      number         
---@field healthbar_icon number        
---@field effect_display EffectDisplay 
---@field on_apply       number        The ID of the callback that runs when the elite type is applied to an actor. <br>The callback function should have the argument actor.


-- ========== Enums ==========

Elite.Property = {
    NAMESPACE      = 0,
    IDENTIFIER     = 1,
    TOKEN_NAME     = 2,
    PALETTE        = 3,
    BLEND_COL      = 4,
    HEALTHBAR_ICON = 5,
    EFFECT_DISPLAY = 6,
    ON_APPLY       = 7,
}
local t = {}
for name, num in pairs(Elite.Property) do t[num] = name end
for i = 0, #t do Elite.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new elite with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the elite.
---@return Elite
Elite.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing elite if found
    local elite = Elite.find(identifier, NAMESPACE, true)
    if elite then return elite end

    -- Create new
    elite = Elite.wrap(gm.elite_type_create(
        NAMESPACE,
        identifier
    ))

    return elite
end

--[[
Searches for the specified elite and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Elite
Elite.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all elite in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>Elite.Property.NAMESPACE by default.
---@return table<number, Elite>
Elite.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an elite wrapper containing the provided elite ID.
]]
---@param id number | Elite The elite to wrap.
---@return Elite
Elite.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Elite
local methods = G.methods_content["Elite"]

--[[
Sets the palette sprite of the elite type.

This also calls `gm.elite_generate_palettes()`.
]]
---@param palette number | Sprite The palette sprite to set.
methods.set_palette = function(self, palette)
    if not palette then throw("sprite is nil") end

    palette = unwrap(palette)
    if type(palette) ~= "number" then throw("Invalid palette argument") end

    self.palette = palette
    gm.elite_generate_palettes()
end

--[[
Prints the elite's properties.
]]
methods.print = function(self) end