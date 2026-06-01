-- EnvironmentLog

---@class EnvironmentLogClass
EnvironmentLog = C["EnvironmentLog"]

local proxy              = P.proxy
local metatable          = W["EnvironmentLog"]
local find_table_wrapper = P.class_find_tables_wrapper["EnvironmentLog"]
local find_table_array   = P.class_find_tables_array["EnvironmentLog"]

local gm                 = gm
local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class EnvironmentLog
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field properties Array The array storing this environment log's properties.
---@field array Array Alias for .properties.

---@class EnvironmentLog
---@field namespace              string  The namespace the log is in.
---@field identifier             string  The identifier for the log within the namespace.
---@field token_name             string  The localization token for the log's name.
---@field token_story            string  The localization token for the log's story.
---@field stage_id               number  The ID of the stage that the log belongs to.
---@field display_room_ids       Array   
---@field initial_cam_x_1080     number  
---@field initial_cam_y_1080     number  
---@field initial_cam_x_720      number  
---@field initial_cam_y_720      number  
---@field initial_cam_alt_x_1080 number  
---@field initial_cam_alt_y_1080 number  
---@field initial_cam_alt_x_720  number  
---@field initial_cam_alt_y_720  number  
---@field is_secret              boolean If true, the log will be hidden in Logbook until acquired.
---@field spr_icon               number  The sprite ID used for the small icon in Logbook (163px x 68px).


-- ========== Enums ==========

EnvironmentLog.Property = {
    NAMESPACE              = 0,
    IDENTIFIER             = 1,
    TOKEN_NAME             = 2,
    TOKEN_STORY            = 3,
    STAGE_ID               = 4,
    DISPLAY_ROOM_IDS       = 5,
    INITIAL_CAM_X_1080     = 6,
    INITIAL_CAM_Y_1080     = 7,
    INITIAL_CAM_X_720      = 8,
    INITIAL_CAM_Y_720      = 9,
    INITIAL_CAM_ALT_X_1080 = 10,
    INITIAL_CAM_ALT_Y_1080 = 11,
    INITIAL_CAM_ALT_X_720  = 12,
    INITIAL_CAM_ALT_Y_720  = 13,
    IS_SECRET              = 14,
    SPR_ICON               = 15,
}
local t = {}
for name, num in pairs(EnvironmentLog.Property) do t[num] = name end
for i = 0, #t do EnvironmentLog.Property[i] = t[i] end


-- ========== Internal ==========

---@param log EnvironmentLog
local function set_correct_log_position(log)
    -- Remove from list
    local log_order = List.wrap(Global.environment_log_display_list)
    log_order:delete_value(log)

    -- Get lowest tier of the stage this log is assigned to
    -- (The stage may be placed multiple times in
    -- the progression, possibly at different tiers)
    local tier = math.huge
    local tiers = Stage.wrap(log.stage_id):get_tiers()
    if #tiers > 0 then tier = tiers[1] end

    -- Set new log position
    -- Sequentually loop through `environment_log_display_list`
    -- until a log with a higher stage tier is reached
    local pos = 0
    while pos < #log_order do
        -- Get current iterated log and its stage
        local _log = log_order:get(pos)
        local _stage = Stage.wrap(EnvironmentLog.wrap(_log).stage_id)

        -- Figure out what its (lowest) tier is
        local _tier = math.huge
        local tiers = _stage:get_tiers()
        if #tiers > 0 then _tier = tiers[1] end

        if tier < _tier then break end
        pos = pos + 1
    end
    
    log_order:insert(pos, log)
end


-- ========== Static Methods ==========

--[[
Creates a new environment log with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the environment log.
---@return EnvironmentLog
EnvironmentLog.new = function(NAMESPACE, identifier)
    check_init_started("new")
    if not identifier then throw("No identifier provided", "new") end

    -- Return existing log if found
    local log = EnvironmentLog.find(identifier, NAMESPACE, true)
    if log then return log end

    -- Create new
    log = EnvironmentLog.wrap(gm.environment_log_create(
        NAMESPACE,
        identifier
    ))

    return log
end

--[[
Creates a new environment log using a stage as a base, <br>
automatically populating the log's properties and <br>
setting the stage's `log_id` property.
]]
---@param stage number | Stage The stage to use as a base.
---@return EnvironmentLog
EnvironmentLog.new_from_stage = function(NAMESPACE, stage)
    check_init_started("new_from_stage")
    if not stage then throw("No stage provided", "new_from_stage") end
    
    stage = Stage.wrap(stage)
    if type(stage.value) ~= "number" then throw("Invalid stage '"..tostring(stage.value).."'", "new_from_stage") end

    -- Use existing log or create a new one
    local log = EnvironmentLog.find(stage.identifier, NAMESPACE, true)
             or EnvironmentLog.new(NAMESPACE, stage.identifier)

    -- Set the stage ID of the log
    -- and the log ID of the stage
    log.stage_id = stage
    stage.log_id = log

    -- Move log position to end of tier
    set_correct_log_position(log)

    -- Reassociate environment logs
    -- (Otherwise shit breaks in Logbook if you call
    -- this *after* already adding rooms to the stage)
    local room_list = List.wrap(stage.room_list)
    local display_room_ids = log.display_room_ids
    for i = 0, #room_list - 1 do
        local room = room_list:get(i)
        if not display_room_ids:contains(room) then
            display_room_ids:push(room)
        end
        gm.room_associate_environment_log(room, log.value, i)
    end

    return log
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
---@param property? number The property to check. <br>EnvironmentLog.Property.NAMESPACE by default.
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

--[[
Sets the initial position of the freecam view in the Logbook.
]]
---@param x number The initial x coordinate.
---@param y number The initial y coordinate.
methods.set_initial_camera_position = function(self, x, y)
    self.initial_cam_x_1080     = x
    self.initial_cam_x_720      = x
    -- self.initial_cam_alt_x_1080 = x  -- No idea what this is actually
    -- self.initial_cam_alt_x_720  = x

    self.initial_cam_y_1080     = y
    self.initial_cam_y_720      = y
    -- self.initial_cam_alt_y_1080 = y
    -- self.initial_cam_alt_y_720  = y
end

--[[
Sets whether or not the log is hidden in Logbook until acquired.

*Technical:* Toggles `is_secret` and moves the log position.
]]
---@param bool boolean `true` - The log is hidden until acquired. <br>`false` - The log is not hidden.
methods.set_hidden = function(self, bool)
    if bool == nil then throw("Missing bool argument") end

    -- Set hidden
    if bool and (not Util.bool(self.is_secret)) then
        self.is_secret = true

        -- Move log position to end
        local log_order = List.wrap(Global.environment_log_display_list)
        log_order:delete_value(self)
        log_order:add(self)

    -- Set not hidden
    elseif (not bool) and Util.bool(self.is_secret) then
        self.is_secret = false

        -- Move log position to end of tier
        set_correct_log_position(self)
    end
end

--[[
Prints the environment log's properties.
]]
methods.print = function(self) end