-- Instance

---@class Instance
Instance = new_class()
C.Instance = Instance

run_on_initial_load(function()
    P.instance_data      = {}   ---@type table<integer, table<string, table<string, table>>>
    
    P.wrapper_cache      = {}   ---@type table<integer, Instance> ID -> Namespace -> Subtable name -> Data table
    P.id_cache           = {}   ---@type table<Instance, integer> Cache for `.id`
    P.object_index_cache = {}   ---@type table<Instance, integer> Cache for `.object_index`/`.__object_index`
    P.ancestor_cache     = {}   ---@type table<integer, boolean> Stores results for `gm.object_is_ancestor(obj_index, gm.constants.pActor)`
end)

local instance_data      = P.instance_data

local wrapper_cache      = P.wrapper_cache
local id_cache           = P.id_cache
local object_index_cache = P.object_index_cache
local ancestor_cache     = P.ancestor_cache

local proxy = P.proxy
local metatable_instance
local metatable_actor
local metatable_player
local gm_id_to_cinst     = gm.CInstance.instance_id_to_CInstance
local constants_oP       = gm.constants.oP

local type                = type
local gm                  = gm                   ---@type table<string, function>
local gm_instance_exists  = gm.instance_exists   ---@type function
local new_proxy           = new_proxy
local wrap                = Wrap.wrap
local unwrap              = Wrap.unwrap

local instance_invalid  ---@type Instance

run_after_core(function()
    metatable_actor  = W.Actor
    metatable_player = W.Player
end)


-- ========== Static Methods ==========

--[[
Returns `true` if the instance exists, and `false` otherwise.
]]
---@param inst integer | Instance The instance to check.
---@return boolean
Instance.exists = function(inst)
    return inst and (gm_instance_exists(unwrap(inst)) == 1)
        or false
end

--[[
Creates and returns an instance of the specified object.
]]
---@param x float The x spawn coordinate.
---@param y float The y spawn coordinate.
---@param object integer | Object The object to spawn.
---@return Instance
Instance.create = function(x, y, object)
    return Instance.wrap(gm.instance_create(x, y, unwrap(object)))
end

--[[
Destroys an instance, or all instances of an object.
]]
---@param inst integer | Instance | Object The instance to destroy, or object index.
Instance.destroy = function(inst)
    if not inst then return end
    inst = unwrap(inst)
    gm.instance_destroy(inst)

    -- Clear instance data
    if type(inst) == "number" and inst < 100000 then return end
    instance_data[inst.id] = nil
end

--[[
Returns the first (or *n*-th) instance of the specified object, <br>
or `Instance.INVALID` if none are found.
]]
---@param object integer | Object The object to check.
---@param n? integer The *n*-th instance, indexed from 1. <br>`1` by default.
---@return Instance
Instance.find = function(object, n)
    object = unwrap(object)
    n = n or 1

    if not object then throw("object is nil") end

    -- GML `instance_find` is faster than `_mod_instance_find`,
    -- so use that for vanilla objects

    -- Vanilla object
    if object < Object.CUSTOM_START then
        local inst = gm.instance_find(object, n - 1)
        if inst ~= -4 then return Instance.wrap(inst) end
    
    -- Custom object
    else
        local inst = gm._mod_instance_find(object, n)   -- `_mod_instance_find` is indexed from 1
        if inst ~= -4 then return Instance.wrap(inst) end

    end

    -- No instance found
    return instance_invalid
end

--[[
Returns a table of all instances of the specified object.

**NOTE:** The execution time scales with the number of <br>
instances of the object, and can be *very* expensive at high numbers. <br>
Try not to call this too much.
]]
---@param object integer | Object The object to check.
---@return table instances
Instance.find_all = function(object)
    object = unwrap(object)
    if not object then throw("object is nil") end

    local insts = {}
    local count = gm._mod_instance_number(object)
    for i = 1, count do
        insts[i] = Instance.find(object, i)
    end
    return insts
end

--[[
Returns the instance of the given object nearest to the specified position, <br>
or `Instance.INVALID` if none are found. <br>
Works with custom objects too.
]]
---@param x float The x coordinate to check from.
---@param y float The y coordinate to check from.
---@param object integer | Object The object to check.
---@return Instance
Instance.nearest = function(x, y, object)
    object = unwrap(object)
    if not x      then throw("x is invalid") end
    if not y      then throw("y is invalid") end
    if not object then throw("object is invalid") end

    return Instance.wrap(gm._mod_instance_nearest(object, x, y))
end

--[[
Returns the instance count of the specified object.
]]
---@param object integer | Object The object to check.
---@return integer
Instance.count = function(object)
    object = unwrap(object)
    if not object then throw("object is nil") end
    return gm._mod_instance_number(object)
end

--[[
Returns a table unique to each instance (will be initially empty) and unique to each mod calling this. <br>
(e.g., Given the same instance and two mods A and B, A calling `get_data` will return a different table to B calling `get_data`).

This table is useful for storing Lua data (such as tables) in instances, which cannot be done with normal instance variables. <br>
It is also faster to access than instance variables. <br>
It is automatically deleted upon the instance's destruction.
]]
---@param instance integer | Instance The instance to get the table for.
---@param subtable? string If specified, returns a different table under the ID `subtable`. <br>Useful for organization and preventing variable name conflicts within a mod itself. <br>This string can be whatever you want.
---@param namespace? string If specified, returns another mod's table for the instance.
---@return table
Instance.get_data = function(instance, subtable, namespace, namespace_is_specified)
    instance = unwrap(instance)
    local id = instance
    local _type = type(instance)
    if _type == "userdata" then id = instance.id end
    if id < 100000 then throw("Instance does not exist") end
    
    subtable  = subtable  or "__main"
    namespace = namespace or RAPI_NAMESPACE -- Internal RAPI calling of this is not namespace-bound

    instance_data[id] = instance_data[id] or {}
    instance_data[id][namespace] = instance_data[id][namespace] or {}
    local ns = instance_data[id][namespace]
    ns[subtable] = ns[subtable] or {}
    return ns[subtable]
end

--[[
Returns an Instance wrapper containing the provided instance.
]]
---@param inst Instance | sol.CInstance* | integer The instance to wrap.
---@return Instance
Instance.wrap = function(inst)
    local _type = type(inst)
    local id

    if _type == "userdata" then
        id = inst.id
        if id < 100000 then return instance_invalid end

        local cached = wrapper_cache[id]
        if cached then return cached end

    elseif _type == "number" then
        if inst < 100000 then return instance_invalid end

        local cached = wrapper_cache[inst]
        if cached then return cached end

        id = inst
        inst = gm_id_to_cinst[id]

    elseif _type == "table" then return inst
    else return instance_invalid
    end

    -- Final check for `inst` being `nil` somehow
    if not inst then return instance_invalid end

    -- Check `object_index` to determine
    -- what metatable should be used
    local obj_index = inst.object_index
    if not obj_index then return instance_invalid end

    local wrapper

    wrapper = new_proxy(inst, metatable_instance)

    -- TODO
    -- Player
    -- if obj_index == constants_oP then
    --     wrapper = new_proxy(inst, metatable_player or W.Player)

    -- else
    --     local is_actor = ancestor_cache[obj_index]
    --     if is_actor == nil then
    --         is_actor = (gm.object_is_ancestor(obj_index, gm.constants.pActor) == 1)
    --         ancestor_cache[obj_index] = is_actor
    --     end

    --     -- Actor
    --     if is_actor then
    --         wrapper = new_proxy(inst, metatable_actor or W.Actor)

    --     -- Instance
    --     else
    --         wrapper = new_proxy(inst, metatable_instance)
    --     end
    -- end

    wrapper_cache[id] = wrapper
    id_cache[wrapper] = id

    return wrapper
end


-- ========== Wrapper Methods ==========

---@class Instance
local methods = {}

-- TODO


-- ========== Metatables ==========

---@class Instance
---@field value sol.CInstance*
---@field cinstance sol.CInstance*
---@field RAPI string

local mt_name = "Instance"

W.Instance = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" or k == "cinstance" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        if k == "id" then return id_cache[t] or -4 end

        -- Methods
        if methods[k] then return methods[k] end

        -- Getter
        local value = proxy[t]
        if not value then return nil end
        local ret = gm.variable_instance_get(value, k)

        -- Return object function callable if key starts with "gml_"
        -- TODO
        -- if not ret then
        --     if k:sub(1, 4) == "gml_" then
        --         return function(self, other)
        --             local value = self.value
        --             if not value then log.error(k..": self does not exist", 2) end
        --             return value[k](value, unwrap(other))
        --         end
        --     end
        -- end

        ret = wrap(ret)

        -- If Script, set its `self`/`other`
        if type(ret) == "table"
        and ret.RAPI == "Script" then
            ret.self  = t  -- Will be unwrapped in Script set
            ret.other = t
        end
        
        return ret
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "value"
        or k == "cinstance"
        or k == "RAPI"
        or k == "id" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local value = proxy[t]
        if not value then return end
        gm.variable_instance_set(value, k, unwrap(v))
    end,

    __eq = function(t, other)
        return t.id == Instance.wrap(other).id
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable_instance = W.Instance


-- Create invalid instance
run_on_initial_load(function()
    ---@type Instance
    P.instance_invalid = new_proxy(nil, metatable_instance)
end)
-- Instance with value `nil` and id `-4`.
Instance.INVALID = P.instance_invalid
instance_invalid = Instance.INVALID