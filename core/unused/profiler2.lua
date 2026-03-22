-- Profiler 2

local frames = 30               -- Takes average of last `frames` frames
local frame_index = 0           -- Circular array index

local scripts = {}              -- Maps script name to `scripts_call_counts` index
local scripts_call_counts = {}  -- Contains tables with info on last `frames` frames

local files = {}
local files_data = {}

local things_to_zero = {}       -- Set counts to 0 for current `frame_index`

__real_gm = __real_gm or gm

gm = setmetatable({}, {
    __index = function(t, k)
        -- Constants
        if k == "constants"             then return __real_gm.constants end
        if k == "constant_types"        then return __real_gm.constant_types end
        if k == "constants_type_sorted" then return __real_gm.constants_type_sorted end
        if k == "CInstance"             then return __real_gm.CInstance end

        -- Store script if not encountered before
        local call_counts
        if not scripts[k] then
            call_counts = {}
            for i = 0, frames - 1 do call_counts[i] = 0 end
            table.insert(scripts_call_counts, call_counts)
            table.insert(things_to_zero, call_counts)
            scripts[k] = #scripts_call_counts
        else
            call_counts = scripts_call_counts[scripts[k]]
        end

        -- Store file if not encountered before
        local info = debug.getinfo(2, "S")
        local name = path.filename(info.short_src)
        local file_data
        if not files[name] then
            file_data = {
                name     = name,
                accesses = {},
                lines    = {},  -- kv pairs
            }
            for i = 0, frames - 1 do file_data.accesses[i] = 0 end
            table.insert(files_data, file_data)
            table.insert(things_to_zero, file_data.accesses)
            files[name] = #files_data
        else
            file_data = files_data[files[name]]
        end

        -- Line numbers of calls
        local line
        if not file_data.lines[info.linedefined] then
            file_data.lines[info.linedefined] = {}
            line = file_data.lines[info.linedefined]
            for i = 0, frames - 1 do line[i] = 0 end
            table.insert(things_to_zero, line)
        else
            line = file_data.lines[info.linedefined]
        end

        -- Closure of script call
        return function(...)
            call_counts[frame_index]        = call_counts[frame_index] + 1
            file_data.accesses[frame_index] = file_data.accesses[frame_index] + 1
            line[frame_index]               = line[frame_index] + 1
            return __real_gm[k](...)
        end
    end,

    __newindex = function(t, k, v) end
})

gm.post_script_hook(gm.constants.__input_system_tick, function()
    frame_index = (frame_index + 1) % frames

    for _, thing in pairs(things_to_zero) do
        thing[frame_index] = 0
    end
end)

local get_avg = function(t)
    local n = 0
    for i = 0, frames - 1 do
        n = n + t[i]
    end
    return n / frames
end

gm.post_script_hook(gm.constants.__input_system_tick, function()
    -- Avg file accesses
    local avgs = {}
    for _, file_data in ipairs(files_data) do
        table.insert(avgs, {file_data.name, get_avg(file_data.accesses)})
    end

    table.sort(avgs, function(a, b) return a[2] > b[2] end)

    local str = "\n"
    for i = 1, 15 do
        local avg = avgs[i]
        str = str..avg[1].." = "..string.format("%.2f", avg[2]).."\n"
    end
    print(str)

    -- Avg line calls for a file
    -- local name = "Instance.lua"
    -- local file_data = files_data[files[name]]

    -- local avgs = {}
    -- for num, line in pairs(file_data.lines) do
    --     table.insert(avgs, {num, get_avg(line)})
    -- end

    -- table.sort(avgs, function(a, b) return a[2] > b[2] end)

    -- local str = "\n"..name.."\n"
    -- for i = 1, math.min(15, #avgs) do
    --     local avg = avgs[i]
    --     str = str..avg[1].." = "..string.format("%.2f", avg[2]).."\n"
    -- end
    -- print(str)
end)