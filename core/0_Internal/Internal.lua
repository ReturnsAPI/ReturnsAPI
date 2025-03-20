-- Internal

__class = {}
__class_mt = {}
__class_mt_builder = {}



if __ref_map then __ref_map:destroy() end
-- __ref_map created in Map.lua



-- Functions

function new_class()
    return {
        internal = {}
    }
end