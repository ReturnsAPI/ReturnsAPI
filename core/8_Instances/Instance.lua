-- Instance

--[[
This class provides get/set functionality for GameMaker instances,
as well as allowing GM function calls with the instance passed in as `self`/`other` using `:` syntax.
]]

Instance = new_class()

run_once(function()
    __instance_data = {}                            -- Unique Lua table for each instance
    __id_cache = setmetatable({}, {__mode = "k"})   -- Cache for inst.id
end)

local wrapper_cache = setmetatable({}, {__mode = "v"})  -- Cache for Instance.wrap
local object_index_cache = {}                           -- Cache for inst:get_object_index; indexed by ID


-- Wrapper types that are Instances
instance_wrappers = {
    Instance    = true,
    Actor       = true,
    Player      = true
}



-- ========== Constants ==========

--@section Constants

--@constants
--[[
INVALID     Instance_with_value_`nil`_and_id_`-4`
]]
-- This is created at the bottom of this file



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`/`cinstance` | CInstance     | *Read-only.* The `sol.CInstance*` of the Instance.
`RAPI`              | string        | *Read-only.* The wrapper name.
`id`                | number        | *Read-only.* The instance ID of the Instance.
`attack_info`       | AttackInfo    | The attack_info struct of *attack instances*. <br>Comes automatically wrapped.

<br>

`Instance`s possess all the builtin [GameMaker instance variables](https://manual.gamemaker.io/lts/en/GameMaker_Language/GML_Reference/Asset_Management/Instances/Instance_Variables/Instance_Variables.htm).
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       bool
--@param        inst        | Instance  | The instance to check.
--[[
Returns `true` if the instance exists, and `false` otherwise.
]]
Instance.exists = function(inst)
    if not inst then return false end
    return (gm.instance_exists(Wrap.unwrap(inst)) == 1)
end


--@static
--@return       Instance
--@param        x           | number    | The x spawn coordinate.
--@param        y           | number    | The y spawn coordinate.
--@param        object      | Object    | The object to spawn.
--[[
Creates and returns an instance of the specified object.

Also exists as a @link {method of Object | Object#create}.
]]
Instance.create = function(x, y, object)
    return Instance.wrap(gm.instance_create(
        Wrap.unwrap(x), 
        Wrap.unwrap(y), 
        Wrap.unwrap(object)
    ))
end


--@static
--@href         destroy-static
--@param        inst        | Instance  | The instance to destroy.
--[[
Destroys the instance.

Also exists as an @link {instance method | Instance#destroy-instance}.
]]
Instance.destroy = function(inst)
    if not inst then return end
    inst = Wrap.unwrap(inst)
    gm.instance_destroy(inst)

    -- Clear instance data
    if type(inst) == "number" and inst < 100000 then return end
    __instance_data[inst.id] = nil
end


--@static
--@return       Instance
--@param        object      | Object    | The object to check.
--@param        n           | number    | The *n*-th instance, indexed from 1. <br>`1` by default.
--[[
Returns the first (or *n*-th) instance of the specified object,
or an @link {invalid instance | Instance#constants} if none are found.
]]
Instance.find = function(object, n)
    object = Wrap.unwrap(object)
    n = n or 1

    if not object then log.error("Instance.find: object is nil", 2) end

    -- GML `instance_find` is faster than `_mod_instance_find`,
    -- so use that for vanilla objects

    -- Vanilla object
    if object < Object.CUSTOM_START then
        local inst = gm.instance_find(object, n - 1)
        if inst ~= -4 then return Instance.wrap(inst) end
    
    -- Custom object
    else
        local inst = gm._mod_instance_find(object, n)   -- _mod_instance_find is indexed from 1
        if inst ~= -4 then return Instance.wrap(inst) end

    end

    -- No instance found
    return Instance.INVALID
end


--@static
--@return       table
--@param        object      | Object    | The object to check.
--[[
Returns a table of all instances of the specified object.

**NOTE:** The execution time scales with the number of
instances of the object, and can be *very* expensive at high numbers.
Try not to call this too much.
]]
Instance.find_all = function(object)
    object = Wrap.unwrap(object)
    if not object then log.error("Instance.find_all: object is nil", 2) end

    local insts = {}

    local count = Instance.count(object)
    for n = 1, count do
        table.insert(insts, Instance.find(object, n))
    end

    return insts
end


--@static
--@return       Instance
--@param        x           | number    | The x position to check from.
--@param        y           | number    | The y position to check from.
--@param        object      | Object    | The object to check.
--[[
Returns the instance of the given object nearest to the specified position,
or an @link {invalid instance | Instance#constants} if none are found.

Works with custom objects too.
]]
Instance.nearest = function(x, y, object)
    x      = Wrap.unwrap(x)
    y      = Wrap.unwrap(y)
    object = Wrap.unwrap(object)

    if not x      then log.error("Instance.nearest: x is invalid", 2) end
    if not y      then log.error("Instance.nearest: y is invalid", 2) end
    if not object then log.error("Instance.nearest: object is invalid", 2) end

    return Instance.wrap(
        gm._mod_instance_nearest(
            object,
            x,
            y
        )
    )
end


--@static
--@return       number
--@param        object      | Object    | The object to check.
--[[
Returns the instance count of the specified object.
]]
Instance.count = function(object)
    object = Wrap.unwrap(object)
    if not object then log.error("Instance.count: object is nil", 2) end
    return gm._mod_instance_number(object)
end


--@static
--@return       table
--@param        instance    | Instance  | The instance to get the table from.
--@optional     subtable    | string    | If specified, returns a different table under the ID `subtable`. <br>Useful for organization and preventing variable name conflicts within a mod itself. <br>This string can be whatever you want.
--@optional     namespace   | string    | If specified, returns another mod's table for the instance.
--[[
Returns a table unique to each instance (will be initially empty) and unique to each mod calling this.
(e.g., Given the same instance and two mods A and B, A calling `get_data` will return a different table to B calling `get_data`).

This table is useful for storing Lua data (such as tables) in instances, which cannot be done with normal instance variables.
It is automatically deleted upon the instance's destruction.
]]
Instance.get_data = function(instance, subtable, namespace, namespace_is_specified)
    local id = Instance.wrap(instance).id
    if id < 100000 then log.error("Instance.get_data: Instance does not exist", 2) end
    
    subtable = subtable or "__main"
    namespace = namespace or RAPI_NAMESPACE -- Internal RAPI calling of this is not namespace-bound

    __instance_data[id] = __instance_data[id] or {}
    __instance_data[id][namespace] = __instance_data[id][namespace] or {}
    local ns = __instance_data[id][namespace]
    ns[subtable] = ns[subtable] or {}
    return ns[subtable]
end


--@static
--@return       Instance
--@param        inst        | CInstance or number   | The CInstance or instance ID to wrap.
--[[
Returns an Instance wrapper containing the provided instance.
]]
Instance.wrap = function(inst)
    -- Get CInstance and ID
    local _type = type(inst)
    local id

    if _type == "userdata" then
        id = inst.id

        -- Check if ID is valid
        -- Sometimes there will be a CInstance but its ID is 0
        if id < 100000 then return Instance.INVALID end

        -- Check cache
        if wrapper_cache[id] then return wrapper_cache[id] end

    elseif _type == "number" then
        -- Check if ID is valid
        if inst < 100000 then return Instance.INVALID end

        -- Check cache
        if wrapper_cache[inst] then return wrapper_cache[inst] end

        id = inst
        inst = gm.CInstance.instance_id_to_CInstance[id]
    
    elseif _type == "table" then return inst
    else return Instance.INVALID
    end

    -- Final check for `inst` being `nil` somehow
    if not inst then return Instance.INVALID end

    -- Get object_index
    local obj_index = inst.object_index
    if not obj_index then return Instance.INVALID end

    -- Check object_index to determine
    -- what metatable should be used
    local wrapper
    
    -- Player
    if obj_index == gm.constants.oP then
        wrapper = make_proxy(inst, metatable_player)

    -- Actor
    elseif gm.object_is_ancestor(obj_index, gm.constants.pActor) == 1 then
        wrapper = make_proxy(inst, metatable_actor)

    -- Instance
    else
        wrapper = make_proxy(inst, metatable_instance)
    end

    -- Store values in caches
    wrapper_cache[id] = wrapper
    __id_cache[wrapper] = id

    return wrapper
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_instance = {}

-- Add GM scripts
for fn_name, fn in pairs(GM_callso) do
    methods_instance[fn_name] = function(self, ...)
        if not self.value then log.error(fn_name..": Instance does not exist", 2) end
        return fn(self, self, ...)
    end
end

Util.table_append(methods_instance, {

    --@instance
    --@href         destroy-instance
    --[[
    Destroys the instance.

    Also exists as a @link {static method | Instance#destroy-static}.
    ]]
    destroy = function(self)
        gm.instance_destroy(self.value)

        -- Clear instance data
        __instance_data[self.id] = nil
    end,


    --@instance
    --@return       Object
    --[[
    Returns the object that the instance is a type of, accounting for custom objects.
    ]]
    get_object = function(self)
        return Object.wrap(self:get_object_index()) -- * This calls the function below, not the vanilla one
    end,


    --@instance
    --@return       number
    --[[
    Returns the instance's correct object *index* (i.e., the actual number), accounting for custom objects.
    ]]
    get_object_index = function(self)
        -- Check cache
        local id = self.id
        local object_index = object_index_cache[id]
        if not object_index then
            object_index = self:get_object_index_self()
            object_index_cache[id] = object_index
        end
        
        return object_index
    end,


    --@instance
    --@return       bool
    --@param        instance    | Instance  | The instance to check.
    --@optional     x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    --@optional     y           | number    | The y position to check at. <br>Uses this instance's current position by default.
    --@overload
    --@return       bool
    --@param        object      | Object    | The object to check.
    --@optional     x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    --@optional     y           | number    | The y position to check at. <br>Uses this instance's current position by default.
    --[[
    Returns `true` if this instance is colliding with a specified instance,
    or *any* instance of a specified object.

    **NOTE:** Checking for the latter with custom objects is *much* slower than with vanilla objects.
    Be mindful of this.
    ]]
    is_colliding = function(self, object, x, y)
        local object = Wrap.unwrap(object)

        -- Instance or Vanilla object
        if (type(object) == "userdata") or (object < Object.CUSTOM_START) then
            return (gm.call(
                "place_meeting",
                self.value,
                nil,
                x or self.x,
                y or self.y,
                object
            ) == 1)

        -- Custom object
        else
            -- Figure out correct object to check
            local obj_array = Object.wrap(object).array
            local object_to_check = obj_array:get(Object.Property.BASE)
            
            local list = List.new()

            local count = gm.call(
                "instance_place_list",
                self.value,
                nil,
                x or self.x,
                y or self.y,
                object_to_check,
                list.value,
                false
            )

            if count > 0 then
                for _, inst in ipairs(list) do
                    -- Check if `__object_index` matches
                    if inst:get_object_index() == object then
                        list:destroy()
                        return true
                    end
                end
            end
            
            list:destroy()
            return false
        end
    end,


    --@instance
    --@return       table
    --@param        object      | Object    | The object to check.
    --@optional     x           | number    | The x position to check at. <br>Uses this instance's current position by default.
    --@optional     y           | number    | The y position to check at. <br>Uses this instance's current position by default.
    --[[
    Returns a table of all instances of the specified object that this instance is colliding with.

    **NOTE:** The execution time scales with the number of
    instances found, and can be somewhat expensive at high numbers.
    Be mindful of this.
    ]]
    get_collisions = function(self, object, x, y)
        local object = Wrap.unwrap(object)

        -- Figure out correct object to check
        local object_to_check = object
        if object >= Object.CUSTOM_START then
            local obj_array = Object.wrap(object).array
            object_to_check = obj_array:get(Object.Property.BASE)
        end

        local insts = {}
        local list = List.new()

        local count = gm.call(
            "instance_place_list",
            self.value,
            nil,
            x or self.x,
            y or self.y,
            object_to_check,
            list.value,
            false
        )

        -- Convert output list to table
        if count > 0 then

            -- Vanilla object
            if object < Object.CUSTOM_START then
                for _, inst in ipairs(list) do
                    table.insert(insts, inst)
                end

            -- Custom object
            else
                for _, inst in ipairs(list) do
                    -- Check if `__object_index` matches
                    if inst:get_object_index() == object then
                        table.insert(insts, inst)
                    end
                end

            end
        end
        
        list:destroy()

        return insts
    end,


    --@instance
    --@return       table
    --@param        object      | Object    | The object to check.
    --@param        x1          | number    | The left side of the rectangle.
    --@param        y1          | number    | The top side of the rectangle.
    --@param        x2          | number    | The right side of the rectangle.
    --@param        y2          | number    | The bottom side of the rectangle.
    --[[
    Returns a table of all instances of the specified object that
    this instance can collide with in the given rectangular area.

    **NOTE:** The execution time scales with the number of
    instances found, and can be somewhat expensive at high numbers.
    Be mindful of this.

    *Technical:* Calls `gm.collision_rectangle_list`.
    ]]
    get_collisions_rectangle = function(self, object, x1, y1, x2, y2)
        local object = Wrap.unwrap(object)

        -- Figure out correct object to check
        local object_to_check = object
        if object >= Object.CUSTOM_START then
            local obj_array = Object.wrap(object).array
            object_to_check = obj_array:get(Object.Property.BASE)
        end

        local insts = {}
        local list = List.new()

        local count = gm.call("collision_rectangle_list", self.value, nil,
            x1,
            y1,
            x2,
            y2,
            object_to_check,
            false,
            true,
            list.value,
            false
        )

        -- Convert output list to table
        if count > 0 then

            -- Vanilla object
            if object < Object.CUSTOM_START then
                for _, inst in ipairs(list) do
                    table.insert(insts, inst)
                end

            -- Custom object
            else
                for _, inst in ipairs(list) do
                    -- Check if `__object_index` matches
                    if inst:get_object_index() == object then
                        table.insert(insts, inst)
                    end
                end

            end
        end
        
        list:destroy()

        return insts
    end,


    --@instance
    --@return       table
    --@param        object      | Object    | The object to check.
    --@param        radius      | number    | The radius of the circle.
    --@optional     x           | number    | The central x position of the circle. <br>Uses this instance's current position by default.
    --@optional     y           | number    | The central y position of the circle. <br>Uses this instance's current position by default.
    --[[
    Returns a table of all instances of the specified object that
    this instance can collide with in the given circular area.

    **NOTE:** The execution time scales with the number of
    instances found, and can be somewhat expensive at high numbers.
    Be mindful of this.

    *Technical:* Calls `gm.collision_circle_list`.
    ]]
    get_collisions_circle = function(self, object, radius, x, y)
        local object = Wrap.unwrap(object)

        -- Figure out correct object to check
        local object_to_check = object
        if object >= Object.CUSTOM_START then
            local obj_array = Object.wrap(object).array
            object_to_check = obj_array:get(Object.Property.BASE)
        end

        local insts = {}
        local list = List.new()

        local count = gm.call("collision_circle_list", self.value, nil,
            x or self.x,
            y or self.y,
            radius,
            object_to_check,
            false,
            true,
            list.value,
            false
        )

        -- Convert output list to table
        if count > 0 then

            -- Vanilla object
            if object < Object.CUSTOM_START then
                for _, inst in ipairs(list) do
                    table.insert(insts, inst)
                end

            -- Custom object
            else
                for _, inst in ipairs(list) do
                    -- Check if `__object_index` matches
                    if inst:get_object_index() == object then
                        table.insert(insts, inst)
                    end
                end

            end
        end
        
        list:destroy()

        return insts
    end,


    --@instance
    --@return       bool
    --@param        tag         | string    | The tag to check.
    --[[
    Returns `true` if this instance is of an object with the specified @link {tag | Object#add_tag}.
    ]]
    has_tag = function(self, tag)
        if type(tag) ~= "string" then log.error("has_tag: tag must be a string", 2) end

        if not __object_tags[tag] then return false end
        if __object_tags[tag][self:get_object_index()] then return true end
        return false
    end,


    --@instance
    --[[
    Prints the instances's variables.
    ]]
    print_variables = function(self)
        local names = Array.wrap(gm.variable_instance_get_names(self.value))

        local str = ""
        for _, name in ipairs(names) do
            str = str.."\n"..Util.pad_string_right(name, 32).." = "..Util.tostring(self[name])
        end
        print(str)
    end

})



-- ========== Metatables ==========

local wrapper_name = "Instance"

make_table_once("metatable_instance", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" or k == "cinstance" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        if k == "id" then return __id_cache[proxy] or -4 end

        -- Methods
        if methods_instance[k] then
            return methods_instance[k]
        end

        -- Getter
        local value = __proxy[proxy]
        if not value then return nil end
        -- local ret = value[k]
        local ret = gm.variable_instance_get(value, k)

        -- Return object function callable if key starts with "gml_"
        if not ret then
            if k:sub(1, 4) == "gml_" then
                return function(self, other)
                    local value = self.value
                    if not value then log.error(k..": self does not exist", 2) end
                    return value[k](value, Wrap.unwrap(other))
                end
            end
        end

        -- For attack instances from `actor:fire_` methods, wrap `attack_info`
        if k == "attack_info" then return AttackInfo.wrap(ret) end

        ret = Wrap.wrap(ret)

        -- If Script, automatically "bind"
        -- to script as self/other
        if type(ret) == "table"
        and ret.RAPI == "Script" then
            ret.self = proxy
            ret.other = proxy
        end

        return ret
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "cinstance"
        or k == "id" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        local value = __proxy[proxy]
        if not value then return end
        -- value[k] = Wrap.unwrap(v)
        gm.variable_instance_set(value, k, Wrap.unwrap(v))
    end,


    __eq = function(proxy, other)
        -- Check if instance IDs are the same
        return proxy.id == Instance.wrap(other).id
    end,

    
    __metatable = "RAPI.Wrapper."..wrapper_name
})



-- ========== __instance_data GC ==========

-- On room change, remove non-existent instances from `__instance_data`

gm.post_script_hook(gm.constants.room_goto, function(self, other, result, args)
    for id, _ in pairs(__instance_data) do
        if not Instance.exists(id) then
            __instance_data[id] = nil
        end
    end

    -- Also remove non-existent cached Instance wrappers
    for id, _ in pairs(wrapper_cache) do
        if not Instance.exists(id) then
            wrapper_cache[id] = nil
        end
    end
end)


-- Remove `__instance_data` on non-player kill

gm.post_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    local actor = Instance.wrap(args[1].value)

    -- Do not clear for player deaths
    local obj_ind = actor:get_object_index()
    if obj_ind ~= gm.constants.oP then
        local id = actor.id
        __instance_data[id] = nil
        wrapper_cache[id]   = nil
    end
end)


-- Move `__instance_data` to new instance

gm.post_script_hook(gm.constants.actor_transform, function(self, other, result, args)
    local actor_id  = Instance.wrap(args[1].value).id
    local new_id    = Instance.wrap(args[2].value).id

    -- Move data
    if __instance_data[actor_id] then
        __instance_data[new_id] = __instance_data[actor_id]
        __instance_data[actor_id] = nil
        wrapper_cache[actor_id]   = nil
    end
end)



-- Create invalid instance
run_once(function()
    __instance_invalid = make_proxy(nil, metatable_instance)
end)
Instance.INVALID = __instance_invalid

-- Public export
__class.Instance = Instance