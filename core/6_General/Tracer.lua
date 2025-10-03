-- Tracer

Tracer = new_class()

run_once(function()
    __tracer_find_table = FindCache.new()
    __tracer_callbacks = {}
end)



-- ========== Constants ==========

--@section Constants

--@constants
--[[
NONE                    0
WISPG                   1
WISPG2                  2
PILOT_RAID              3
PILOT_RAID_BOOSTED      4
PILOT_PRIMARY           5
PILOT_PRIMARY_STRONG    6
PILOT_PRIMARY_ALT       7
COMMANDO1               8
COMMANDO2               9
COMMANDO3               10
COMMANDO3_R             11
SNIPER1                 12
SNIPER2                 13
ENGI_TURRET             14
ENFORCER1               15
ROBOMANDO1              16
ROBOMANDO2              17
BANDIT1                 18
BANDIT2                 19
BANDIT2_R               20
BANDIT3                 21
BANDIT3_R               22
ACRID                   23
NO_SPARKS_ON_MISS       24
END_SPARKS_ON_PIERCE    25
DRILL                   26
PLAYER_DRONE            27
]]

local tracer_constants = {
    NONE                    = 0,
    WISPG                   = 1,
    WISPG2                  = 2,
    PILOT_RAID              = 3,
    PILOT_RAID_BOOSTED      = 4,
    PILOT_PRIMARY           = 5,
    PILOT_PRIMARY_STRONG    = 6,
    PILOT_PRIMARY_ALT       = 7,
    COMMANDO1               = 8,
    COMMANDO2               = 9,
    COMMANDO3               = 10,
    COMMANDO3_R             = 11,
    SNIPER1                 = 12,
    SNIPER2                 = 13,
    ENGI_TURRET             = 14,
    ENFORCER1               = 15,
    ROBOMANDO1              = 16,
    ROBOMANDO2              = 17,
    BANDIT1                 = 18,
    BANDIT2                 = 19,
    BANDIT2_R               = 20,
    BANDIT3                 = 21,
    BANDIT3_R               = 22,
    ACRID                   = 23,
    NO_SPARKS_ON_MISS       = 24,
    END_SPARKS_ON_PIERCE    = 25,
    DRILL                   = 26,
    PLAYER_DRONE            = 27,
}

-- Add to Tracer directly (e.g., Tracer.COMMANDO1)
for k, v in pairs(tracer_constants) do
    Tracer[k] = v
end



-- ========== Internal ==========

Tracer.internal.initialize = function()
    -- Populate find table with vanilla tracers
    for constant, id in pairs(tracer_constants) do
        local namespace = "ror"
        local identifier = constant:lower()

        local struct = Global.tracer_info:get(id)

        -- Custom properties
        struct.namespace    = namespace
        struct.identifier   = identifier

        __tracer_find_table:set(
            {
                wrapper = Tracer.wrap(id),
                struct  = struct
            },
            identifier, namespace, id
        )
    end

    -- Update cached wrappers
    __tracer_find_table:loop_and_update_values(function(value)
        return {
            wrapper = Tracer.wrap(value.wrapper),
            struct  = value.struct
        }
    end)
end
table.insert(_rapi_initialize, Tracer.internal.initialize)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the tracer.
`RAPI`          | string    | *Read-only.* The wrapper name.

<br>

Property | Type | Description
| - | - | -
`namespace`                         | string    | The namespace the tracer is in.
`identifier`                        | string    | The identifier for the tracer within the namespace.
`consistent_sparks_flip`            | bool      | 
`show_sparks_if_miss`               | bool      | 
`sparks_offset_y`                   | number    | 
`show_end_sparks_on_piercing_hit`   | bool      | 
`override_sparks_miss`              | number    | 
`override_sparks_solid`             | number    | 
`draw_tracer`                       | bool      | 
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return   Tracer
--@param    identifier      | string    | The identifier for the tracer.
--[[
Creates a new tracer with the given identifier if it does not already exist,
or returns the existing one if it does.
]]
Tracer.new = function(NAMESPACE, identifier)
    -- Return existing tracer if found
    local tracer = Tracer.find(identifier, NAMESPACE)
    if tracer then return tracer end

    -- Get next usable ID for tracer
    local tracer_info_array = Global.tracer_info
    local id = #tracer_info_array

    local struct = Struct.new(
        gm.constants.TracerKindInfo

        -- Default constructor args
        -- consistent_sparks_flip           false
        -- show_sparks_if_miss              true
        -- sparks_offset_y                  0
        -- show_end_sparks_on_piercing_hit  false
        -- override_sparks_miss             -1
        -- override_sparks_solid            -1
        -- draw_tracer                      true
    )

    -- Custom properties
    struct.namespace    = NAMESPACE
    struct.identifier   = identifier

    -- Push onto array
    tracer_info_array:push(struct)

    local tracer = Tracer.wrap(id)

    -- Add to find table
    __tracer_find_table:set(
        {
            wrapper = tracer,
            struct  = struct
        },
        identifier, NAMESPACE, id
    )

    return tracer
end


--@static
--@return       Tracer or nil
--@param        identifier  | string    | The identifier to search for.
--@optional     namespace   | string    | The namespace to search in.
--[[
Searches for the specified tracer and returns it.
If no namespace is provided, searches in your mod's namespace first, and vanilla tracers second.
]]
Tracer.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __tracer_find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end

    return nil
end


--@static
--@return       Tracer
--@param        tracer      | number    | The tracer to wrap.
--[[
Returns a Tracer wrapper containing the provided tracer.
]]
Tracer.wrap = function(tracer)
    -- Input:   number or Tracer wrapper
    -- Wraps:   number
    return make_proxy(Wrap.unwrap(tracer), metatable_tracer)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_tracer = {

    --@instance
    --[[
    Prints the tracer's properties.
    ]]
    print_properties = function(self)
        local struct = __tracer_find_table:get(self.value).struct
        struct:print()
    end,


    --@instance
    --@param        func        | function  | The function to set. <br>The parameters for it are `x1, y1, x2, y2, tracer_col`.
    --[[
    Sets the function that gets called whenever the tracer spawns.
    ]]
    set_callback = function(self, func)
        __tracer_callbacks[self.value] = func
    end

}



-- ========== Metatables ==========

local wrapper_name = "Tracer"

make_table_once("metatable_tracer", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end

        -- Methods
        if methods_tracer[k] then
            return methods_tracer[k]
        end

        -- Getter
        local struct = __tracer_find_table:get(__proxy[proxy]).struct
        return struct[k]
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local struct = __tracer_find_table:get(__proxy[proxy]).struct
        struct[k] = Wrap.unwrap(v)
    end,

    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== Hooks ==========

gm.post_script_hook(gm.constants.bullet_draw_tracer, function(self, other, result, args)
    local tracer_kind = args[1].value

    local fn = __tracer_callbacks[tracer_kind]
    if not fn then return end

    local tracer_col = args[2].value
    local x1 = args[3].value
    local y1 = args[4].value
    local x2 = args[5].value
    local y2 = args[6].value

    fn(x1, y1, x2, y2, tracer_col)
end)



-- Public export
__class.Tracer = Tracer