-- ReadOnly

-- This version has no support for read-only on specific keys
-- since that has significantly increased performance cost

-- Additionally, ReadOnly.new should be called to *finalize* the lock

run_once(function()
    local wrapper_name = "ReadOnly"
    local metatable_readonly = {
        __index = function(proxy, k)
            if k == "RAPI" then return wrapper_name end
            return __proxy[proxy][k]
        end,
        
        __newindex = function(proxy, k, v)
            log.error("Table is read-only", 2)
        end,

        __call = function(proxy, ...)
            return __proxy[proxy](...)
        end,

        __len = function(proxy)
            return #__proxy[proxy]
        end,

        __eq = function(p1, p2)
            return __proxy[p1] == __proxy[p2]
        end,

        __pairs = function(proxy)
            return next, __proxy[proxy], nil
        end,

        __metatable = "RAPI.Wrapper."..wrapper_name
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
            return make_proxy(t, metatable_readonly)
        end
    }
end)



-- Public export
__class.ReadOnly = ReadOnly