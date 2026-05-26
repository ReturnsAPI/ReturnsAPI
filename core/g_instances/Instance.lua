-- Instance

---@class InstanceClass
Instance = new_class()
C.Instance = Instance

run_on_initial_load(function()
    P.instance_data                 = {}   ---@type table<number, table<string, table<string, table>>>
    P.instance_id_cache             = setmetatable({}, {__mode = "k"})  ---@type table<Instance, number> Cache for `id`
    P.instance_obj_ind_cache        = setmetatable({}, {__mode = "k"})  ---@type table<Instance, number> Cache for `object_index`
    P.instance_custom_obj_ind_cache = setmetatable({}, {__mode = "k"})  ---@type table<Instance, number> Cache for `__object_index`
    P.instance_wrapper_type         = setmetatable({}, {__mode = "k"})  ---@type table<Instance, number> Cache for wrapper type (`1` to `3`)
end)

local instance_data        = P.instance_data
local id_cache             = P.instance_id_cache
local obj_ind_cache        = P.instance_obj_ind_cache
local custom_obj_ind_cache = P.instance_custom_obj_ind_cache
local wrapper_type         = P.instance_wrapper_type

local proxy = P.proxy

local type               = type
local tostring           = tostring
local getmetatable       = debug.getmetatable
local string_sub         = string.sub
local gm                 = gm                   ---@type table<string, function>
local gm_instance_create = gm.instance_create   ---@type function
local gm_instance_exists = gm.instance_exists   ---@type function
local unwrap             = Wrap.unwrap

local gm_id_to_cinst = gm.CInstance.instance_id_to_CInstance    ---@type table<number, sol.CInstance*>
local constants_oP   = gm.constants.oP  ---@type number

local ancestor_lookup = {}  ---@type table<number, boolean> Maps objects to booleans of whether or not they inherit from `pActor`
for obj_index = 0, 900 do
    if gm.object_exists(obj_index) then
        ancestor_lookup[obj_index] = (gm.object_is_ancestor(obj_index, gm.constants.pActor) == 1)
    end
end


-- ========== Static Methods ==========

--[[
Creates and returns an instance of the specified object.
]]
---@param x number The x spawn coordinate.
---@param y number The y spawn coordinate.
---@param object number | Object The object to spawn.
---@return Instance
Instance.create = function(x, y, object)
    return gm_instance_create(x, y, unwrap(object))
end

--[[
Destroys an instance, or all instances of an object.
]]
---@param inst number | Instance | Object The instance to destroy, or object index.
Instance.destroy = function(inst)
    if not inst then return end
    local id = inst.id
    instance_data[id] = nil
    gm.instance_destroy(inst)
end

--[[
Returns `true` if the instance exists, and `false` otherwise.
]]
---@param inst number | Instance The instance to check.
---@return boolean
Instance.exists = function(inst)
    return inst and gm_instance_exists(inst) == 1
        or false
end

--[[
Returns the first (or *n*-th) instance of the specified object, <br>
or `nil` if none are found.
]]
---@param object number | Object The object to check.
---@param n? number The *n*-th instance, indexed from 1. <br>`1` by default.
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
---@param object number | Object The object to check.
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
or `nil` if none are found. <br>
Works with custom objects too.
]]
---@param x number The x coordinate to check from.
---@param y number The y coordinate to check from.
---@param object number | Object The object to check.
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
---@param object number | Object The object to check.
---@return number
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
---@param instance number | Instance The instance to get the table for.
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
---@param inst number | sol.CInstance* | Instance The instance to wrap.
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
    local obj_index = custom_obj_ind_cache[self]
    if not obj_index then
        obj_index = self:get_object_index_self() ---@type number
        custom_obj_ind_cache[self] = obj_index
    end
    return Object.wrap(obj_index)
end

--[[
Returns the instance's correct object index, accounting for custom objects.
]]
---@return number object_index
methods.get_object_index = function(self)
    local obj_index = custom_obj_ind_cache[self]
    if not obj_index then
        obj_index = self:get_object_index_self() ---@type number
        custom_obj_ind_cache[self] = obj_index
    end
    return obj_index
end

--[[
Returns `true` if this instance is colliding with a specified instance, <br>
or *any* instance of a specified object.

**NOTE:** Checking for custom objects is slower than vanilla objects.
]]
---@param object Object | Instance
---@param x? number The x coordinate to check at. <br>Uses this instance's current x position by default.
---@param y? number The y coordinate to check at. <br>Uses this instance's current y position by default.
---@return boolean
methods.is_colliding = function(self, object, x, y)
    object = unwrap(object)
    x = x or self.x
    y = y or self.y

    -- Instance or vanilla object
    if type(object) == "userdata"
    or object < Object.CUSTOM_START then
        return gm.call("place_meeting", self, nil, x, y, object) == 1
    end

    -- Custom object
    local obj_array = Object.wrap(object).properties
    local object_to_check = obj_array:get(Object.Property.BASE)

    local list = List.new()
    local count = gm.call(
        "instance_place_list",
        self,
        nil,
        x,
        y,
        object_to_check,
        proxy[list],
        false
    )
    if count > 0 then
        for _, inst in ipairs(list) do
            if inst:get_object_index() == object then
                list:destroy()
                return true
            end
        end
    end
    list:destroy()
    return false
end

--[[
Returns a table of all instances of the specified object <br>
that this instance is colliding with.

**NOTE:** Performance cost scales with the number of instances found.
]]
---@param object Object
---@param x? number Uses this instance's current x position by default.
---@param y? number Uses this instance's current y position by default.
---@return table<number, Instance>
methods.get_collisions = function(self, object, x, y)
    object = unwrap(object)
    x = x or self.x
    y = y or self.y

    local object_to_check = object
    if object >= Object.CUSTOM_START then
        local obj_array = Object.wrap(object).properties
        object_to_check = obj_array:get(Object.Property.BASE)
    end

    local insts, i = {}, 1
    local list = List.new()
    local count = gm.call(
        "instance_place_list",
        self,
        nil,
        x,
        y,
        object_to_check,
        proxy[list],
        false
    )
    if count > 0 then
        -- Vanilla object
        if object < Object.CUSTOM_START then
            for _, inst in ipairs(list) do
                insts[i] = inst
                i = i + 1
            end

        -- Custom object
        else
            for _, inst in ipairs(list) do
                if inst:get_object_index() == object then
                    insts[i] = inst
                    i = i + 1
                end
            end
        end
    end
    list:destroy()
    return insts
end

--[[
Returns a table of all instances of the specified object <br>
that this instance can collide with in the given rectangular area.

*Technical:* Calls `gm.collision_rectangle_list`. <br>
**NOTE:** Performance cost scales with the number of instances found.
]]
---@param object Object
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return table<number, Instance>
methods.get_collisions_rectangle = function(self, object, x1, y1, x2, y2)
    object = unwrap(object)

    local object_to_check = object
    if object >= Object.CUSTOM_START then
        local obj_array = Object.wrap(object).properties
        object_to_check = obj_array:get(Object.Property.BASE)
    end

    local insts, i = {}, 1
    local list = List.new()
    local count = gm.call(
        "collision_rectangle_list",
        self,
        nil,
        x1,
        y1,
        x2,
        y2,
        object_to_check,
        false,
        true,
        proxy[list],
        false
    )
    if count > 0 then
        -- Vanilla object
        if object < Object.CUSTOM_START then
            for _, inst in ipairs(list) do
                insts[i] = inst
                i = i + 1
            end

        -- Custom object
        else
            for _, inst in ipairs(list) do
                if inst:get_object_index() == object then
                    insts[i] = inst
                    i = i + 1
                end
            end
        end
    end
    list:destroy()
    return insts
end

--[[
Returns a table of all instances of the specified object <br>
that this instance can collide with in the given circular area.

*Technical:* Calls `gm.collision_circle_list`.
]]
---@param object Object
---@param radius number
---@param x? number Uses this instance's current x position by default.
---@param y? number Uses this instance's current y position by default.
---@return table
methods.get_collisions_circle = function(self, object, radius, x, y)
    object = unwrap(object)
    x = x or self.x
    y = y or self.y

    local object_to_check = object
    if object >= Object.CUSTOM_START then
        local obj_array = Object.wrap(object).properties
        object_to_check = obj_array:get(Object.Property.BASE)
    end

    local insts, i = {}, 1
    local list = List.new()
    local count = gm.call(
        "collision_circle_list",
        self,
        nil,
        x,
        y,
        radius,
        object_to_check,
        false,
        true,
        list.value,
        false
    )
    if count > 0 then
        -- Vanilla object
        if object < Object.CUSTOM_START then
            for _, inst in ipairs(list) do
                insts[i] = inst
                i = i + 1
            end

        -- Custom object
        else
            for _, inst in ipairs(list) do
                if inst:get_object_index() == object then
                    insts[i] = inst
                    i = i + 1
                end
            end
        end
    end
    list:destroy()
    return insts
end

--[[
Returns `true` if this instance is of an object with the specified tag.
]]
---@param tag string
---@return boolean
methods.has_tag = function(self, tag)
    if tag == "count" then throw("'count' is reserved") end

    local t = P.object_tags[tag]
    if not t then return false end
    return t[self:get_object_index()] ~= nil
end

--[[
Prints the instance's variables.
]]
methods.print_variables = function(self)
    local names = gm.variable_instance_get_names(self)
    local str = ""
    for _, name in ipairs(names) do
        str = string.format(
            "%s\n%s = %s",
            str,
            String.pad_right(name, 32),
            tostring(self[name])
        )
    end
    print(str)
end


-- ========== Metatables ==========

---@class Instance
---@field RAPI string The name of this wrapper.
---@field id number
---@field [string] any

local inst = gm.instance_create(0, 0, gm.constants.oB)
local mt = getmetatable(inst)
gm.instance_destroy(inst)

run_on_initial_load(function()
    P.instance_og_index    = mt.__index     ---@type function
    P.instance_og_newindex = mt.__newindex  ---@type function
end)
local og_index    = P.instance_og_index
local og_newindex = P.instance_og_newindex

local methods_actor  ---@type table<string, function>
local methods_player ---@type table<string, function>
run_after_core(function()
    methods_actor  = G.methods_actor  or {}
    methods_player = G.methods_player or {}
end)

local mt_names = {"Instance", "Actor", "Player"}

W.Instance = {
    __index = function(t, k)
        if k == "id" then
            local id = id_cache[t]
            if not id then
                id = og_index(t, "id")
                id_cache[t] = id
            end
            return id
        end

        -- Since `sol.CInstance*` can only have 1 metatable,
        -- Instance, Actor, and Player mts have been combined
        -- Need to tell which type this is via `object_index`
        local _type = wrapper_type[t]
        if not _type then
            local obj_index = obj_ind_cache[t]
            if not obj_index then
                obj_index = og_index(t, "object_index") ---@type number
                obj_ind_cache[t] = obj_index
            end
            _type = 1
            if     obj_index == constants_oP  then _type = 3
            elseif ancestor_lookup[obj_index] then _type = 2
            end
            wrapper_type[t] = _type
        end

        if k == "RAPI" then return mt_names[_type] end

        -- Methods
        if _type == 3 then
            local method = methods_player[k]
            if method then return method end
        end
        if _type >= 2 then
            local method = methods_actor[k]
            if method then return method end
        end
        local method = methods[k]
        if method then return method end

        -- Getter
        -- local ret = gm.variable_instance_get(t, k)
        local ret = og_index(t, k)

        -- Return object function callable if key starts with "gml_"
        -- TODO assess if this is still required since we are modifying sol directly now
        -- if not ret then
        --     if string_sub(k, 1, 4) == "gml_" then
        --         return function(self, other)
        --             return self[k](self, other)
        --         end
        --     end
        -- end

        -- TODO add AttackInfo wrapping

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
        if k == "RAPI"
        or k == "id" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        -- gm.variable_instance_set(t, k, unwrap(v))
        og_newindex(t, k, unwrap(v))
    end,

    __eq = function(t, other)
        return t.id == other.id
    end,

    __tostring = function(t)
        return t.RAPI..": "..get_usertype_pointer(t)
    end,
}

table.merge(mt, W.Instance)