-- File

--[[
Slightly easier syntax wrapper for `toml`.
Files are stored in `paths.plugins_data()`.
]]

File = new_class()

run_once(function()
    __file_wrapper_bank = {}
end)



-- ========== Properties ==========

--@section Properties

--[[
**Wrapper**
Property | Type | Description
| - | - | -
`value`         | number    | *Read-only.* The filename being used.
`RAPI`          | string    | *Read-only.* The wrapper name.
`path`          | string    | *Read-only.* The filepath being used.
]]



-- ========== Static Methods ==========

--@section Static Methods

--@static
--@return       File
--@optional     name        | string    | The filename to use. <br>Automatically prepended with your namespace. <br>Adding an extension is *not* required; `".toml"` is automatically appended.
--[[
Creates a new File and returns it.
]]
File.new = function(NAMESPACE, name)    
    return make_proxy(NAMESPACE..((name and "-"..tostring(name)) or ""), metatable_file)
end



-- ========== Instance Methods ==========

--@section Instance Methods

methods_file = {

    --@instance
    --@return       table
    --[[
    Loads the stored data from the file.
    ]]
    read = function(self)
        local success, file = pcall(toml.decodeFromFile, self.path)
        if not success then log.error("toml read error: "..file.reason, 2) end
        return file
    end,


    --@instance
    --@param        table           | table     | The table to write.
    --[[
    Overwrites the file with a table.
    ]]
    write = function(self, t)
        local success, err = pcall(toml.encodeToFile, t, { file = self.path, overwrite = true })
        if not success then log.error("toml write error: "..err, 2) end
    end

}



-- ========== Metatables ==========

local wrapper_name = "File"

make_table_once("metatable_file", {
    __index = function(proxy, k)
        -- Get wrapped value
        if k == "value" then return __proxy[proxy] end
        if k == "RAPI" then return wrapper_name end
        if k == "path" then
            return path.combine(paths.plugins_data(), __proxy[proxy]..".toml")
        end

        -- Methods
        if methods_file[k] then
            return methods_file[k]
        end

        return nil
    end,


    __newindex = function(proxy, k, v)
        -- Throw read-only error for certain keys
        if k == "value"
        or k == "RAPI"
        or k == "path" then
            log.error("Key '"..k.."' is read-only", 2)
        end

        -- Setter
        log.error("File has no properties to set", 2)
    end,


    __metatable = "RAPI.Wrapper."..wrapper_name
})



__class.File = File