-- Instance

---@class Instance
Instance = new_class()
C.Instance = Instance

run_on_initial_load(function()
    P.instance_data = {}    ---@type table<integer, table<string, table<string, table>>>
end)

local instance_data  = P.instance_data

local gm_id_to_cinst = gm.CInstance.instance_id_to_CInstance    ---@type table<integer, sol.CInstance*>
local constants_oP   = gm.constants.oP  ---@type integer

local type               = type
local getmetatable       = debug.getmetatable
local gm                 = gm                   ---@type table<string, function>
local gm_instance_create = gm.instance_create   ---@type function
local gm_instance_exists = gm.instance_exists   ---@type function
local unwrap             = Wrap.unwrap

local ancestor_lookup = {}  ---@type table<integer, boolean> Maps objects to booleans of whether or not they inherit from `pActor`
for obj_index = 0, 900 do
    if gm.object_exists(obj_index) then
        ancestor_lookup[obj_index] = (gm.object_is_ancestor(obj_index, gm.constants.pActor) == 1)
    end
end


-- ========== Static Methods ==========

--[[
Returns `true` if the instance exists, and `false` otherwise.
]]
---@param inst integer | Instance The instance to check.
---@return boolean
Instance.exists = function(inst)
    return inst and gm_instance_exists(inst) == 1
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
    return gm_instance_create(x, y, unwrap(object))
end

--[[
Destroys an instance, or all instances of an object.
]]
---@param inst integer | Instance | Object The instance to destroy, or object index.
Instance.destroy = function(inst)
    if not inst then return end
    local id = inst.id
    instance_data[id] = nil
    gm.instance_destroy(inst)
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
        if inst ~= -4 then return inst end
    
    -- Custom object
    else
        local inst = gm._mod_instance_find(object, n)   -- `_mod_instance_find` is indexed from 1
        if inst ~= -4 then return inst end
    end

    return nil
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
    return gm._mod_instance_nearest(object, x, y)
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
    local id = instance.id
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
**[!] DEPRECATED**

Returns an Instance wrapper containing the provided instance.
]]
---@deprecated
---@param inst Instance | sol.CInstance* | integer The instance to wrap.
---@return Instance
Instance.wrap = function(inst)
    return inst
end


-- ========== Wrapper Methods ==========

---@class Instance
local methods = {}

-- Add GM scripts
for script_name, fn in pairs(GM.SO) do
    methods[script_name] = function(self, ...)
        return fn(self, self, ...)
    end
end

--[[
Destroys the instance.
]]
methods.destroy = function(self)
    instance_data[self.id] = nil
    gm.instance_destroy(self)
end

--[[
Returns the object that the instance is a type of, accounting for custom objects.
]]
---@return Object
methods.get_object = function(self)
    return Object.wrap(self:get_object_index_self())
end

--[[
Returns the instance's correct object index, accounting for custom objects.
]]
---@return integer object_index
methods.get_object_index = function(self) 
    return self:get_object_index_self()
end


-- ========== Metatables ==========

---@class Instance
---@field RAPI string

local inst = gm.instance_create(0, 0, gm.constants.oB)
local mt = getmetatable(inst)
gm.instance_destroy(inst)

run_on_initial_load(function()
    P.instance_og_index    = mt.__index
    P.instance_og_newindex = mt.__newindex
end)
local og_index = P.instance_og_index
local og_newindex = P.instance_og_newindex

local mt_name = "Instance"

W.Instance = {
    __index = function(t, k)
        if k == "RAPI" then
            local obj_index = og_index(t, "object_index")
            if obj_index == constants_oP then
                return "Player"
            elseif ancestor_lookup[obj_index] then
                return "Actor"
            end
            return "Instance"
        end

        -- Methods
        if methods[k] then return methods[k] end

        -- Getter
        -- local ret = gm.variable_instance_get(t, k)
        local ret = og_index(t, k)

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

        -- If Script, set its `self`/`other`
        local mt = getmetatable(ret)
        if mt and mt.__name == "sol.CScriptRef*" then
            ret.self  = t
            ret.other = t
        end
        
        return ret
    end,

    __newindex = function(t, k, v)
        -- Throw read-only error
        if k == "RAPI" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        -- gm.variable_instance_set(t, k, unwrap(v))
        og_newindex(t, k, unwrap(v))
    end,

    __eq = function(t, other)
        return t.id == other.id
    end,
}

table.merge(mt, W.Instance)