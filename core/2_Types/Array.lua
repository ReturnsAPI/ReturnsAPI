-- Array

Array = new_class()



-- ========== Static Methods ==========

Array.new = function(arg1, arg2)
    -- Overload 1
    -- Create array from table
    if type(arg1) == "table" then
        local holder = ffi.new("struct RValue[2]")
        holder[0] = gmf.rvalue_new(0)
        holder[1] = gmf.rvalue_new(0)
        local out = gmf.rvalue_new(0)
        gmf.array_create(out, nil, nil, 2, holder)
        local arr = Array.wrap(out)

        -- Add elements from table to array
        for _, v in ipairs(arg1) do
            arr:push(Wrap.unwrap(v))
        end
        return arr
    end

    -- Overload 2
    -- Create array with optional size and default value
    local holder = ffi.new("struct RValue[2]")
    holder[0] = gmf.rvalue_new(arg1 or 0)
    holder[1] = gmf.rvalue_new(arg2 or 0)
    local out = gmf.rvalue_new(0)
    gmf.array_create(out, nil, nil, 2, holder)
    return Array.wrap(out)
end


Array.wrap = function(array)
    if not Array.is(array) then log.error("Value is not an array", 2) end
    return Proxy.new(array, metatable_array)
end


Array.is = function(value)
    value = Wrap.unwrap(value)
    if type(value) == "cdata" and value.type == Wrap.Type.ARRAY then return true end
    return false
end



-- ========== Instance Methods ==========

methods_array = {

    get = function(self, index)
        local holder = ffi.new("struct RValue[2]")
        holder[0] = self.value
        holder[1] = gmf.rvalue_new(index)
        local out = gmf.rvalue_new(0)
        gmf.array_get(out, nil, nil, 2, holder)
        return Wrap.wrap(out)
    end,


    set = function(self, index, value)
        local holder = ffi.new("struct RValue[3]")
        holder[0] = self.value
        holder[1] = gmf.rvalue_new(index)

        -- value
        if type(value) == "number" then
            holder[2] = gmf.rvalue_new(value)
        elseif type(value) == "string" then
            holder[2] = gmf.rvalue_new_string(value)
        else
            holder[2] = value
        end

        gmf.array_set(nil, nil, nil, 3, holder)
    end,


    size = function(self)
        local holder = ffi.new("struct RValue[1]")
        holder[0] = self.value
        local out = gmf.rvalue_new(0)
        gmf.array_length(out, nil, nil, 1, holder)
        return Wrap.wrap(out)
    end,


    push = function(self, ...)
        local values = {...}

        local holder = ffi.new("struct RValue[2]")
        holder[0] = self.value

        for _, v in ipairs(values) do
            -- value
            if type(v) == "number" then
                holder[1] = gmf.rvalue_new(v)
            elseif type(v) == "string" then
                holder[1] = gmf.rvalue_new_string(v)
            else
                holder[1] = v
            end

            gmf.array_push(nil, nil, nil, 2, holder)
        end
    end
    
}



-- ========== Metatables ==========

metatable_array_class = {
    __call = function(t, arg1, arg2)
        -- Wrap
        if Array.is(arg1) then return Array.wrap(arg1) end

        -- Pass to Array.new
        return Array.new(arg1, arg2)
    end,


    __metatable = "RAPI.Class.Array"
}
setmetatable(Array, metatable_array_class)


metatable_array = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return Proxy.get(t) end
        if k == "type" then return getmetatable(t):sub(14, -1) end
        
        -- Methods
        if methods_array[k] then
            return methods_array[k]
        end

        -- Getter
        k = tonumber(Wrap.unwrap(k))
        if k and k >= 1 then -- and k <= #t then
            return t:get(k - 1)
        end
        return nil
    end,
    

    __newindex = function(t, k, v)
        -- Setter
        k = tonumber(Wrap.unwrap(k))
        if k then t:set(k - 1, Wrap.unwrap(v)) end
    end,
    
    
    __len = function(t)
        return t:size()
    end,


    __metatable = "RAPI.Wrapper.Array"
}



_CLASS["Array"] = Array
_CLASS_MT["Array"] = metatable_array_class