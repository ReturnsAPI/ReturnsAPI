-- Tracer

Tracer = new_class()

run_once(function()
    __tracer_find_table = FindCache.new()
    __tracer_funcs = {}
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



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The ID of the tracer.
`RAPI`          | string    | *Read-only.* The wrapper name.
]]



-- ========== Static Methods ==========

Tracer.new = function(NAMESPACE, identifier)
    local tracer = Tracer.find(identifier, NAMESPACE)
    if tracer then return tracer end

    local tracer_info_array = Global.tracer_info
    local index = #tracer_info_array

    local struct = Struct.new()
    struct.namespace                       = NAMESPACE     -- RAPI custom variable
    struct.identifier                      = identifier    -- RAPI custom variable
    struct.consistent_sparks_flip          = false
    struct.show_sparks_if_miss             = true
    struct.sparks_offset_y                 = 0
    struct.show_end_sparks_on_piercing_hit = false
    struct.override_sparks_miss            = -1
    struct.override_sparks_solid           = -1
    struct.draw_tracer                     = true

    tracer_info_array:push(struct)

    local wrapper = Tracer.wrap(index)

    -- Add to find table
    __tracer_find_table:set(
        {
            wrapper = wrapper,
            struct  = struct
        },
        identifier, NAMESPACE, index
    )

    return wrapper
end


Tracer.find = function(identifier, namespace, namespace_is_specified)
    -- Check in find table
    local cached = __tracer_find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end

    return nil
end


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
    set_func = function(self, func)
        __tracer_funcs[self.value] = func
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

    -- don't waste time on vanilla tracers
    if tracer_kind <= tracer_constants.PLAYER_DRONE then return end

    local tracer_col = args[2].value
    local x1 = args[3].value
    local y1 = args[4].value
    local x2 = args[5].value
    local y2 = args[6].value

    local fn = __tracer_funcs[tracer_kind]
    if fn then
        fn(x1, y1, x2, y2, tracer_col)
    end
end)



-- Public export
__class.Tracer = Tracer