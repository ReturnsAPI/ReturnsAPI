-- Class

Class = {}

local file_path = _ENV["!plugins_mod_folder_path"].."/core/data/class_name_mapping.txt"
local success, file = pcall(toml.decodeFromFile, file_path)
class_rapi_to_gm = file.mapping
class_gm_to_rapi = {}
for k, v in pairs(class_rapi_to_gm) do
    class_gm_to_rapi[v] = k
end

Class_tables = {}



for class_rapi, class_gm in pairs(class_rapi_to_gm) do

    -- Class_tables[class_rapi]

end



return {Class}