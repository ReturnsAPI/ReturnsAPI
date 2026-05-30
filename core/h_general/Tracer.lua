-- Tracer

---@class TracerClass
Tracer = new_class()
C.Tracer = Tracer

run_on_initial_load(function()
    P.tracer_find_table_wrapper = FindTable.new()
    P.tracer_find_table_struct  = FindTable.new()
    P.tracer_functions          = {}  ---@type table<number, function>
end)

local wrapper_table    = P.tracer_find_table_wrapper
local struct_table     = P.tracer_find_table_struct
local tracer_functions = P.tracer_functions

local proxy = P.proxy
local metatable

local new_proxy = new_proxy
local unwrap    = Wrap.unwrap


-- ========== Constants ==========

Tracer.NONE                 = 0
Tracer.WISPG                = 1
Tracer.WISPG2               = 2
Tracer.PILOT_RAID           = 3
Tracer.PILOT_RAID_BOOSTED   = 4
Tracer.PILOT_PRIMARY        = 5
Tracer.PILOT_PRIMARY_STRONG = 6
Tracer.PILOT_PRIMARY_ALT    = 7
Tracer.COMMANDO1            = 8
Tracer.COMMANDO2            = 9
Tracer.COMMANDO3            = 10
Tracer.COMMANDO3_R          = 11
Tracer.SNIPER1              = 12
Tracer.SNIPER2              = 13
Tracer.ENGI_TURRET          = 14
Tracer.ENFORCER1            = 15
Tracer.ROBOMANDO1           = 16
Tracer.ROBOMANDO2           = 17
Tracer.BANDIT1              = 18
Tracer.BANDIT2              = 19
Tracer.BANDIT2_R            = 20
Tracer.BANDIT3              = 21
Tracer.BANDIT3_R            = 22
Tracer.ACRID                = 23
Tracer.NO_SPARKS_ON_MISS    = 24
Tracer.END_SPARKS_ON_PIERCE = 25
Tracer.DRILL                = 26
Tracer.PLAYER_DRONE         = 27

-- Populate `tracer_constants`

local tracer_constants = {}  ---@type table<number, string> Array table of vanilla tracers (indexed from `1`).
for name, tracer in pairs(Tracer) do
    if type(tracer) == "number" then
        tracer_constants[tracer + 1] = name
    end
end


-- ========== Internal ==========

local function populate_find_table()
    -- Populate find table with vanilla tracers
    for tracer, name in pairs(tracer_constants) do
        local identifier = name:lower()
        local struct     = Global.tracer_info:get(tracer - 1)

        -- Custom properties
        struct.namespace  = "ror"
        struct.identifier = identifier

        wrapper_table:set(Tracer.wrap(id), identifier, "ror", tracer - 1)
        struct_table:set(struct, identifier, "ror", tracer - 1)
    end
end
run_on_initialize(populate_find_table)


-- ========== Static Methods ==========

--[[
Creates a new tracer with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the tracer.
---@return Tracer
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
    struct.namespace  = NAMESPACE
    struct.identifier = identifier

    -- Push onto array
    tracer_info_array:push(struct)

    local wrapper = Tracer.wrap(id)
    wrapper_table:set(wrapper, identifier, NAMESPACE, id)
    struct_table:set(struct, identifier, NAMESPACE, id)
    return wrapper
end

--[[
Searches for the specified tracer and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param identifier string The identifier to search for.
---@param namespace? string The namespace to search in.
---@return Tracer | nil
Tracer.find = function(identifier, namespace, namespace_is_specified)
    return wrapper_table:get(identifier, namespace, namespace_is_specified)
end

--[[
Returns a table of all tracers in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
---@param namespace? string The namespace to search in.
---@return table<number, Tracer>
Tracer.find_all = function(namespace, namespace_is_specified)
    return wrapper_table:get_all(namespace, namespace_is_specified)
end

--[[
Returns a Tracer wrapper containing the provided tracer.
]]
---@param tracer number | Tracer The tracer to wrap.
---@return Tracer
Tracer.wrap = function(tracer)
    return new_proxy(unwrap(tracer), metatable)
end


-- ========== Wrapper Methods ==========

---@class Tracer
local methods = {}

--[[
Sets the function that gets called while the tracer is drawn.
]]
---@param func function The function to set. <br>The parameters for it are `x1, y1, x2, y2, color`.
methods.set_callback = function(self, func)
    tracer_functions[proxy[self]] = func
end

--@instance
--[[
Prints the tracer's properties.
]]
methods.print = function(self)
    struct_table[proxy[self]].value:print()
end


-- ========== Metatables ==========

---@class Tracer
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class Tracer
---@field namespace                        string   The namespace the tracer is in.
---@field identifier                       string   The identifier for the tracer within the namespace.
---@field consistent_sparks_flip           boolean  
---@field show_sparks_if_miss              boolean  
---@field sparks_offset_y                  number   
---@field show_end_sparks_on_piercing_hit  boolean  
---@field override_sparks_miss             number   
---@field override_sparks_solid            number   
---@field draw_tracer                      boolean  

local mt_name = "Tracer"

W.Tracer = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end

        -- Methods
        local method = methods[k]
        if method then return method end

        -- Getter
        local struct = struct_table[proxy[t]].value
        return struct[k]
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local struct = struct_table[proxy[t]].value
        struct[k] = unwrap(v)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.Tracer


-- ========== Hooks ==========

gm.post_script_hook(gm.constants.bullet_draw_tracer, function(self, other, result, args)
    local tracer_kind = args[1].value

    local fn = tracer_functions[tracer_kind]
    if not fn then return end

    local tracer_col = args[2].value
    local x1 = args[3].value
    local y1 = args[4].value
    local x2 = args[5].value
    local y2 = args[6].value

    fn(x1, y1, x2, y2, tracer_col)
end)