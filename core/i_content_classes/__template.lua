if true then return end

-- CLASS_UPPER

---@class CLASS_UPPERClass
CLASS_UPPER = C["CLASS_UPPER"]

local proxy      = P.proxy
local metatable  = W["CLASS_UPPER"]
local find_table = P.class_find_tables["CLASS_UPPER"]

local check_init_started = Initialize.internal.check_if_started
local unwrap             = Wrap.unwrap


-- ========== Annotations ==========

---@class CLASS_UPPER
---@field value number The value being wrapped.
---@field RAPI string The name of this wrapper.

---@class CLASS_UPPER
-- Populate with properties


-- ========== Enums ==========

CLASS_UPPER.Property = {

}
for name, num in pairs(CLASS_UPPER.Property) do CLASS_UPPER.Property[num] = name end


-- ========== Static Methods ==========

--[[
Creates a new CLASS_LOWER with the given identifier if it does not already exist, <br>
or returns the existing one if it does.
]]
---@param identifier string The identifier for the CLASS_LOWER.
---@return CLASS_UPPER
-- CLASS_UPPER.new = function(NAMESPACE, identifier)

-- end

--[[
Searches for the specified CLASS_LOWER and returns it.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.
]]
CLASS_UPPER.find = function(identifier, namespace, namespace_is_specified)
    check_init_started()
    local cached = find_table:get(identifier, namespace, namespace_is_specified)
    if cached then return cached.wrapper end
end

--[[
Returns a table of all CLASS_LOWER in the specified namespace.

If no namespace is provided, searches globally in a non-deterministic* order. <br>
\* Guaranteed to check in your mod's namespace first.

**NOTE:** Filtering by a non-namespace property is *very slow*! <br>
Try not to do that too much.
]]
CLASS_UPPER.find_all = function(NAMESPACE, filter, property)
    check_init_started("find_all")
    property = property or 0  -- `namespace` filter by default

    -- Namespace filter
    if property == 0 then
        local namespace_is_specified = (filter ~= nil)
        return find_table:get_all(filter or NAMESPACE, namespace_is_specified)
    end

    -- Other filter (very slow!)
    -- Loop over entire find table
    local out, i = {}, 1
    for id = 0, #find_table - 1 do
        local element = find_table[id].value
        if element.properties:get(property) == filter then
            out[i] = element.wrapper
            i = i + 1
        end
    end
    return out
end

--[[
Returns a CLASS_LOWER wrapper containing the provided CLASS_LOWER ID.
]]
---@param id number | CLASS_UPPER The CLASS_LOWER to wrap.
---@return CLASS_UPPER
CLASS_UPPER.wrap = function(id)
    return new_proxy(unwrap(id), metatable)
end


-- ========== Wrapper Methods ==========

---@class CLASS_UPPER
local methods = G.methods_content["CLASS_UPPER"]

-- Insert other methods before `print`

--[[
Prints the CLASS_LOWER's properties.
]]
methods.print = function(self)
    local array = find_table:get(proxy[self]).array
    local str = ""
    for i, v in ipairs(array) do
        str = str.."\n"..string.pad_right(CLASS_UPPER.Property[i - 1], 32).." = "..tostring(v)
    end
    print(str)
end