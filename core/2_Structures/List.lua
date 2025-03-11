-- List

List = new_class()



-- ========== Static Methods ==========

List.new = function(table)
    
end


List.wrap = function(list)
    
end



-- ========== Instance Methods ==========

methods_list = {

    

}



-- ========== Metatables ==========

metatable_list_class = {
    __call = function(t, value, arg2)
        
    end,


    __metatable = "RAPI.Class.List"
}
setmetatable(List, metatable_list_class)


metatable_list = {
    __index = function(t, k)
        
    end,
    

    __newindex = function(t, k, v)
        
    end,
    
    
    __len = function(t)
        
    end,


    __pairs = function(t)
        
    end,


    __ipairs = function(t)
        
    end,

    
    __metatable = "RAPI.Wrapper.List"
}



_CLASS["List"] = List
_CLASS_MT["List"] = metatable_list_class