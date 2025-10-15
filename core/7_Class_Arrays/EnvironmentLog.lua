-- EnvironmentLog

local name_rapi = class_name_g2r["class_environment_log"]
EnvironmentLog = __class[name_rapi]



-- ========== Enums ==========

--@section Enums

--@enum
--@name Property
--[[
NAMESPACE               0
IDENTIFIER              1
TOKEN_NAME              2
TOKEN_STORY             3
STAGE_ID                4
DISPLAY_ROOM_IDS        5
INITIAL_CAM_X_1080      6
INITIAL_CAM_Y_1080      7
INITIAL_CAM_X_720       8
INITIAL_CAM_Y_720       9
INITIAL_CAM_ALT_X_1080  10
INITIAL_CAM_ALT_Y_1080  11
INITIAL_CAM_ALT_X_720   12
INITIAL_CAM_ALT_Y_720   13
IS_SECRET               14
SPR_ICON                15
]]



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The item log ID being wrapped.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                 | string    | The namespace the log is in.
`identifier`                | string    | The identifier for the log within the namespace.
`token_name`                | string    | The localization token for the log's name.
`token_story`               | string    | The localization token for the log's story.
`stage_id`                  | number    | The ID of the stage that the log belongs to.
`display_room_ids`          | Array     | 
`initial_cam_x_1080`        | number    | 
`initial_cam_y_1080`        | number    | 
`initial_cam_x_720`         | number    | 
`initial_cam_y_720`         | number    | 
`initial_cam_alt_x_1080`    | number    | 
`initial_cam_alt_y_1080`    | number    | 
`initial_cam_alt_x_720`     | number    | 
`initial_cam_alt_y_720`     | number    | 
`is_secret`                 | bool      | If `true`, the log will be hidden in Logbook until acquired.
`spr_icon`                  | sprite    | The sprite used for the small icon in Logbook (163px x 68px).
]]



-- ========== Internal ==========

EnvironmentLog.internal.set_correct_log_position = function(log)
    -- Remove from list
    local log_order = Global.environment_log_display_list
    log_order:delete_value(log)

    -- Get lowest tier of log's stage
    local tier = 1000
    local tiers, not_empty = Stage.wrap(log.stage_id):get_tiers()
    if not_empty then tier = tiers[1] end

    local order = Global.stage_progression_order    -- Array of Lists

    -- Set new log position
    -- Sequentually loop through `environment_log_display_list`
    -- until a log with a higher stage tier is reached
    local pos = 0
    while pos < #log_order do
        -- Get current iterated log and its stage
        local _log = log_order:get(pos)
        local _stage = Stage.wrap(EnvironmentLog.wrap(_log).stage_id)

        -- Figure out what its (lowest) tier is
        local _tier = 1000
        local tiers, not_empty = _stage:get_tiers()
        if not_empty then _tier = tiers[1] end

        if tier < _tier then break end
        pos = pos + 1
    end
    
    log_order:insert(pos, log)
end



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   EnvironmentLog
--@param    identifier  | string    | The identifier for the environment log.
--[[
Creates a new environment log with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
EnvironmentLog.new = function(NAMESPACE, identifier)
    Initialize.internal.check_if_started("EnvironmentLog.new")
    if not identifier then log.error("EnvironmentLog.new: No identifier provided", 2) end

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


--@static
--@return   EnvironmentLog
--@param    stage           | Stage     | The stage to use as a base.
--[[
Creates a new environment log using a stage as a base,
automatically populating the log's properties and
setting the stage's `log_id` property.
]]
EnvironmentLog.new_from_stage = function(NAMESPACE, stage)
    Initialize.internal.check_if_started("EnvironmentLog.new_from_stage")
    
    if not stage then log.error("EnvironmentLog.new_from_stage: No stage provided", 2) end
    stage = Stage.wrap(stage)

    if type(stage.value) ~= "number" then log.error("EnvironmentLog.new_from_stage: Invalid stage", 2) end

    -- Use existing log or create a new one
    local log = EnvironmentLog.find(stage.identifier, NAMESPACE, true)
             or EnvironmentLog.new(NAMESPACE, stage.identifier)

    -- Set the stage ID of the log
    -- and the log ID of the stage
    log.stage_id = stage
    stage.log_id = log

    -- Move log position to end of tier
    EnvironmentLog.internal.set_correct_log_position(log)

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


--@static
--@name         find
--@return       EnvironmentLog or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified environment log and returns it.
If no namespace is provided, searches in your mod's namespace first, and "ror" second.
]]


--@static
--@name         find_all
--@return       table
--@param        filter      |           | The filter to search by.
--@optional     property    | number    | The property to check. <br>@link {`EnvironmentLog.Property.NAMESPACE` | EnvironmentLog#Property} by default.
--[[
Returns a table of environment logs matching the specified filter and property.

**NOTE:** Filtering by a non-namespace property is *very slow*!
Try not to do that too much.
]]


--@static
--@name         wrap
--@return       EnvironmentLog
--@param        id          | number    | The environment log ID to wrap.
--[[
Returns an EnvironmentLog wrapper containing the provided environment log ID.
]]



-- ========== Instance Methods ==========

--@section Instance Methods

Util.table_append(methods_class_array[name_rapi], {

    --@instance
    --@name         print_properties
    --[[
    Prints the environment log's properties.
    ]]


    --@instance
    --@param        x           | number    | The initial x position.
    --@param        y           | number    | The initial y position.
    --[[
    Sets the initial position of the freecam view in the Logbook.
    ]]
    set_initial_camera_position = function(self, x, y)
        self.initial_cam_x_1080     = x
        self.initial_cam_x_720      = x
        -- self.initial_cam_alt_x_1080 = x  -- No idea what this is actually
        -- self.initial_cam_alt_x_720  = x

        self.initial_cam_y_1080     = y
        self.initial_cam_y_720      = y
        -- self.initial_cam_alt_y_1080 = y
        -- self.initial_cam_alt_y_720  = y
    end,


    --@instance
    --@param        bool        | bool      | `true` - The log is hidden until acquired. <br>`false` - The log is not hidden.
    --[[
    Sets whether or not the log is hidden in Logbook until acquired.
    
    *Technical:* Toggles `is_secret` and moves the log position.
    ]]
    set_hidden = function(self, bool)
        if bool == nil then log.error("set_hidden: Missing bool argument", 2) end

        -- Set hidden
        if bool and (not Util.bool(self.is_secret)) then
            self.is_secret = true

            -- Move log position to end
            local log_order = Global.environment_log_display_list
            log_order:delete_value(self)
            log_order:add(self)


        -- Set not hidden
        elseif (not bool) and Util.bool(self.is_secret) then
            self.is_secret = false

            -- Move log position to end of tier
            EnvironmentLog.internal.set_correct_log_position(self)
        end
    end

})