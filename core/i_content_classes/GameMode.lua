-- GameMode

---@class GameModeClass
GameMode = C["GameMode"]

local proxy              = P.proxy
local metatable          = W["GameMode"]
local find_table_wrapper = P.class_find_tables_wrapper["GameMode"]
local find_table_array   = P.class_find_tables_array["GameMode"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class GameMode
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class GameMode
-- Populate with properties


-- ========== Enums ==========

GameMode.Property = {

}
local t = {}
for name, num in pairs(GameMode.Property) do t[num] = name end
for i = 0, #t do GameMode.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new game mode with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the game mode.
---@return GameMode
GameMode.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified game mode and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return GameMode
GameMode.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all game mode in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`GameMode.Property.NAMESPACE` by default.
---@return table<number, GameMode>
GameMode.find_all = function(NAMESPACE, filter, property) end

--[[
Returns a game mode wrapper containing the provided game mode ID.
]]
---@param id number | GameMode The game mode to wrap.
---@return GameMode
GameMode.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class GameMode
local methods = G.methods_content["GameMode"]

-- Insert other methods before `print`

--[[
Prints the game mode's properties.
]]
methods.print = function(self) end