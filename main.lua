-- ReturnsAPI

PATH = _ENV["!plugins_mod_folder_path"].."/"


-- ENVY initial setup
mods["MGReturns-ENVY"].auto()
envy = mods["MGReturns-ENVY"]


-- Load core
class_refs = {}
local dirs = path.get_directories(PATH.."core")
for _, dir in ipairs(dirs) do
    local files = path.get_files(dir)
    for _, file in ipairs(files) do
        name = path.filename(file):sub(1, -5)
        class_refs[name] = require(file)
    end
end


-- ENVY public setup
require("./envy")