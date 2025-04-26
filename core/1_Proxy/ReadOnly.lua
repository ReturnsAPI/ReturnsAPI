-- ReadOnly

-- This version has no support for read-only *keys*
-- since that has significantly increased performance cost

-- Additionally, ReadOnly.new should be called to *finalize* the lock

run_once(function()
    local metatable_readonly = {
        __index = function(proxy, k)
            if k == "RAPI" then return getmetatable(proxy):sub(14, -1) end
            return Proxy.get(proxy)[k]
        end,
        
        __newindex = function(proxy, k, v)
            log.error("Table is read-only", 2)
        end,

        __call = function(proxy, ...)
            return Proxy.get(proxy)(...)
        end,

        __len = function(proxy)
            return #Proxy.get(proxy)
        end,

        __eq = function(p1, p2)
            return Proxy.get(p1) == Proxy.get(p2)
        end,

        __pairs = function(proxy)
            return next, Proxy.get(proxy), nil
        end,

        __metatable = "RAPI.Wrapper.ReadOnly"
    }

    ReadOnly = {

        --@section Static Methods

        --@static
        --@return       table
        --@param        t       | table     | The table to make read-only.
        --[[
        Returns a read-only version of the provided table.
        ]]
        new = function(t)
            return Proxy.new(t, metatable_readonly)
        end

    }
end)



-- Public export
__class.ReadOnly = ReadOnly