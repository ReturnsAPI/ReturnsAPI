-- Artifact

---@class ArtifactClass
Artifact = C["Artifact"]

local proxy              = P.proxy
local metatable          = W["Artifact"]
local find_table_wrapper = P.class_find_tables_wrapper["Artifact"]
local find_table_array   = P.class_find_tables_array["Artifact"]

local Achievement        = Achievement
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class Artifact
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this artifact's properties.
---@field array Array Alias for .properties.

---@class Artifact
---@field namespace         string  The namespace the artifact is in.
---@field identifier        string  The identifier for the artifact within the namespace.
---@field token_name        string  The localization token for the artifact's name.
---@field token_pickup_name string  
---@field token_description string  
---@field sprite_loadout_id number  
---@field sprite_pickup_id  number  
---@field on_set_active     number  The ID of the callback that runs when entering *and* exiting a run with the artifact enabled. <br>The callback function should have the argument active (true when entering and false when exiting).
---@field active            boolean true while in a run with the artifact enabled.
---@field achievement_id    number  The achievement ID of the artifact. <br>If *not* -1, the artifact will be locked until the achievement is unlocked.


-- ========== Enums ==========

Artifact.Property = {
    NAMESPACE         = 0,
    IDENTIFIER        = 1,
    TOKEN_NAME        = 2,
    TOKEN_PICKUP_NAME = 3,
    TOKEN_DESCRIPTION = 4,
    SPRITE_LOADOUT_ID = 5,
    SPRITE_PICKUP_ID  = 6,
    ON_SET_ACTIVE     = 7,
    ACTIVE            = 8,
    ACHIEVEMENT_ID    = 9,
}
local t = {}
for name, num in pairs(Artifact.Property) do t[num] = name end
for i = 0, #t do Artifact.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new artifact with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the artifact.
---@return Artifact
Artifact.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing artifact if found
    local artifact = Artifact.find(identifier, NAMESPACE, true)
    if artifact then return artifact end

    -- Create new
    artifact = Artifact.wrap(gm.artifact_create(
        NAMESPACE,
        identifier
    ))

    return artifact
end

--[[
Searches for the specified artifact and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Artifact
Artifact.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all artifact in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>Artifact.Property.NAMESPACE by default.
---@return table<number, Artifact>
Artifact.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an artifact wrapper containing the provided artifact ID.
]]
---@param id number | Artifact The artifact to wrap.
---@return Artifact
Artifact.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class Artifact
local methods = G.methods_content["Artifact"]

--[[
Returns the associated @link {Achievement | Achievement} if it exists, <br>
or an invalid Achievement if it does not.
]]
---@return Achievement
methods.get_achievement = function(self)
    return Achievement.wrap(self.achievement_id)
end

--[[
Prints the artifact's properties.
]]
methods.print = function(self) end