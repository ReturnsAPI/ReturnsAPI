-- EnvironmentLog

---@class EnvironmentLogClass
EnvironmentLog = C["EnvironmentLog"]

local proxy              = P.proxy
local metatable          = W["EnvironmentLog"]
local find_table_wrapper = P.class_find_tables_wrapper["EnvironmentLog"]
local find_table_array   = P.class_find_tables_array["EnvironmentLog"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class EnvironmentLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this environment log's properties.
---@field array Array Alias for `.properties`.

---@class EnvironmentLog
---@field namespace                       = 0
---@field identifier                      = 1
---@field token_name                      = 2
---@field token_story                     = 3
---@field stage_id                        = 4
---@field display_room_ids                = 5
---@field initial_cam_x_1080              = 6
---@field initial_cam_y_1080              = 7
---@field initial_cam_x_720               = 8
---@field initial_cam_y_720               = 9
---@field initial_cam_alt_x_1080          = 10
---@field initial_cam_alt_y_1080          = 11
---@field initial_cam_alt_x_720           = 12
---@field initial_cam_alt_y_720           = 13
---@field is_secret                       = 14
---@field spr_icon                        = 15


-- ========== Enums ==========

EnvironmentLog.Property = {

}
local t = {}
for name, num in pairs(EnvironmentLog.Property) do t[num] = name end
for i = 0, #t do EnvironmentLog.Property[i] = t[i] end


-- ========== Static Methods ==========

--[[
Creates a new environment log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the environment log.
---@return EnvironmentLog
EnvironmentLog.new = function(NAMESPACE, identifier)
    throw("Method has not been created for this class yet", "new")
end

--[[
Searches for the specified environment log and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return EnvironmentLog
EnvironmentLog.find = function(identifier, namespace, namespace_is_specified) end

--[[
Returns a table of all environment log in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
---@param filter any The filter to search by.
---@param property? number The property to check. <br>`EnvironmentLog.Property.NAMESPACE` by default.
---@return table<number, EnvironmentLog>
EnvironmentLog.find_all = function(NAMESPACE, filter, property) end

--[[
Returns an environment log wrapper containing the provided environment log ID.
]]
---@param id number | EnvironmentLog The environment log to wrap.
---@return EnvironmentLog
EnvironmentLog.wrap = function(id) end


-- ========== Wrapper Methods ==========

---@class EnvironmentLog
local methods = G.methods_content["EnvironmentLog"]

-- Insert other methods before `print`

--[[
Prints the environment log's properties.
]]
methods.print = function(self) end