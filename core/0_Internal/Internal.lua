-- Internal

__class = {}
__class_mt = {}
__class_mt_builder = {}

-- __ref_map created in Map.lua



-- Functions

function new_class()
    return {
        internal = {}
    }
end


function parse_optional_namespace(namespace, default_namespace)
    local is_specified = false
    if namespace then
        if namespace == "~" then namespace = default_namespace end
        is_specified = true
    else namespace = default_namespace
    end
    return namespace, is_specified
end