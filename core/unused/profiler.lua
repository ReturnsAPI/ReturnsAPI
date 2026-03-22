-- Profiler

local calls = {}
local from = {}
local call_index = 0
local avg_of_n_frames = 30

__real_gm = __real_gm or gm

gm = setmetatable({}, {
    __index = function(t, k)
        if k == "constants"             then return __real_gm.constants end
        if k == "constant_types"        then return __real_gm.constant_types end
        if k == "constants_type_sorted" then return __real_gm.constants_type_sorted end

        if not calls[k] then
            calls[k] = {}
            for i = 0, avg_of_n_frames - 1 do
                calls[k][i] = 0
            end
        end

        local info = debug.getinfo(2, "S")
        local filename = path.filename(info.short_src)
        if not from[filename] then
            from[filename] = {}
            for i = 0, avg_of_n_frames - 1 do
                from[filename][i] = 0
            end
        end

        local call = calls[k]
        local fr = from[filename]

        return function(...)
            call[call_index] = call[call_index] + 1
            fr[call_index]   = fr[call_index] + 1

            return __real_gm[k](...)
        end
    end
})

gm.post_script_hook(gm.constants.__input_system_tick, function()
    call_index = (call_index + 1) % avg_of_n_frames

    for _, call in pairs(calls) do
        call[call_index] = 0
    end

    for _, fr in pairs(from) do
        fr[call_index] = 0
    end
end)

local get_avg = function(k)
    local call = calls[k]
    if not call then return end
    
    local n = 0
    for i = 0, avg_of_n_frames - 1 do
        n = n + call[i]
    end

    return n / avg_of_n_frames
end

local get_avg_from = function(k)
    local fr = from[k]
    if not fr then return end
    
    local n = 0
    for i = 0, avg_of_n_frames - 1 do
        n = n + fr[i]
    end

    return n / avg_of_n_frames
end

gm.post_script_hook(gm.constants.__input_system_tick, function()
    -- testing
    print(get_avg("variable_global_get"))
    print(get_avg_from("Global.lua"))
end)