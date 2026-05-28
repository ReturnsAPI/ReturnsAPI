-- TOML

--[[
Slightly easier syntax wrapper for `toml`. <br>
Files are stored in `paths.plugins_data()` (or a specified path).
]]
---@class TOMLClass
TOML = new_class()
C.TOML = TOML

run_on_initial_load(function()
    P.toml_directories = setmetatable({}, {__mode = "k"})   ---@type table<TOML, string> Maps TOML wrappers to cwd.
end)

local proxy = P.proxy
local metatable

local tostring  = tostring
local pcall     = pcall
local path      = path  ---@type table<string, function>
local paths     = paths ---@type table<string, function>
local toml      = toml  ---@type table<string, function>
local new_proxy = new_proxy


-- ========== Static Methods ==========

--[[
Creates a new TOML wrapper and returns it.
]]
---@param name string The filename to use. <br>Automatically prepended with your namespace. <br>Adding an extension is *not* required; `".toml"` is automatically appended.
---@param directory string The directory to create in. <br>`paths.plugins_data()` by default.
---@return TOML
TOML.new = function(NAMESPACE, name, directory)
    local wrapper = new_proxy(NAMESPACE..((name and "-"..tostring(name)) or ""), metatable)
    P.toml_directories[wrapper] = directory or paths.plugins_data()
    return wrapper
end


-- ========== Wrapper Methods ==========

---@class TOML
local methods = {}

--[[
Reads the stored data from the file. <br>
Returns `nil` if the file does not exist.
]]
---@return table | nil
methods.read = function(self)
    local success, file = pcall(toml.decodeFromFile, self.path)
    if not success then
        -- Ignore error from non-existent file
        if file.reason == "File could not be opened for reading" then
            return nil
        end
        log.error("toml read error: "..file.reason, 2)
    end
    return file
end

--[[
Overwrites the file with a table.
]]
---@param t table The table to write.
methods.write = function(self, t)
    local success, err = pcall(toml.encodeToFile, t, { file = self.path, overwrite = true })
    if not success then log.error("toml write error: "..err, 2) end
end


-- ========== Metatables ==========

---@class TOML
---@field value string The value being wrapped.
---@field RAPI string The name of this wrapper.
---@field path string The filepath being used.

local mt_name = "TOML"

W.TOML = {
    __index = function(t, k)
        -- Get wrapped value
        if k == "value" then return proxy[t] end
        if k == "RAPI" then return mt_name end
        if k == "path" then
            return path.combine(P.toml_directories[t], proxy[t]..".toml")
        end

        -- Methods
        local method = methods[k]
        if method then return method end
    end,

    __newindex = function(t, k, v)
        log.error(mt_name.." has no properties to set", 2)
    end,

    __metatable = mt_wrapper_name(mt_name),
}
metatable = W.TOML