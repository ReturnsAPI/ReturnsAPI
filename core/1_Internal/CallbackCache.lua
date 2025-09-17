-- CallbackCache

-- Cache base that allows adding and removing
-- callback functions, with a numerical priority system.

-- Used by
-- * Callback
-- * Initialize
-- * RecalculateStats

run_once(function()

    CallbackCache = {
        new = function()
            return setmetatable({
                current_id  = 0,    -- Unique ID for each callback fn
                id_lookup   = {},   -- Lookup callback function data tables by ID
                sections    = {}    -- Separate into sections, each having their own priorities
            }, callback_cache_mt)
        end
    }


    callback_cache_mt = {
        __index = {

            -- Register a callback function
            -- Stored as a function data table
            -- Returns a unique ID
            add = function(self, fn, namespace, priority, section)
                priority = priority or 0    -- Higher values run before lower ones
                section = section or "main"

                -- Create section table if it does not exist
                -- Used by Callback to separate by callback types
                if not self.sections[section] then
                    self.sections[section] = {
                        priorities = {}  -- List of priorities in use
                    }
                end
                local section_table = self.sections[section]

                -- Create priority table in section if it does not exist
                if not section_table[priority] then
                    section_table[priority] = {}
                    table.insert(section_table.priorities, priority)
                    table.sort(section_table.priorities, function(a, b) return a > b end)
                end

                -- Get unique ID and increment
                local id = self.current_id
                self.current_id = self.current_id + 1

                -- Create callback function data table
                local fn_table = {
                    id          = id,
                    fn          = fn,
                    namespace   = namespace,
                    priority    = priority,
                    section     = section
                }

                -- Add callback function data table to priority table
                table.insert(section_table[priority], fn_table)
                self.id_lookup[id] = fn_table

                -- Return ID
                return id
            end,


            -- Remove a function data table by ID
            remove = function(self, id)
                -- Find callback function data table
                local fn_table = self.id_lookup[id]
                if not fn_table then return end
                self.id_lookup[id] = nil

                -- Get relevant section and priority table
                local section_table = self.sections[fn_table.section]
                local priority_table = section_table[fn_table.priority]
                for i, v in ipairs(priority_table) do
                    if v == fn_table then
                        table.remove(priority_table, i)
                        break
                    end
                end

                -- Delete priority table if empty
                if #priority_table <= 0 then
                    section_table[fn_table.priority] = nil
                    for i, v in ipairs(section_table.priorities) do
                        if v == fn_table.priority then
                            table.remove(section_table.priorities, i)
                            break
                        end
                    end
                end

                -- Return callback function
                return fn_table.fn
            end,


            -- Remove all function data tables
            -- added by a namespace
            remove_all = function(self, namespace)
                -- Loop through sections
                for _, section_table in pairs(self.sections) do

                    -- Loop through priority tables
                    for priority, priority_table in pairs(section_table) do
                        if type(priority) == "number" then

                            -- Loop through priority table and remove
                            -- data tables with matching namespace
                            for i = #priority_table, 1, -1 do
                                local fn_table = priority_table[i]
                                if fn_table.namespace == namespace then
                                    table.remove(priority_table, i)
                                    self.id_lookup[fn_table.id] = nil
                                end
                            end

                            -- Delete priority table if empty
                            if #priority_table <= 0 then
                                section_table[priority] = nil
                                for i, v in ipairs(section_table.priorities) do
                                    if v == priority then
                                        table.remove(section_table.priorities, i)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end,


            -- Call a function on all function data
            -- tables in a section in priority order
            -- Function should accept `fn_table` as only argument
            loop_and_call_function = function(self, fn, section)
                section = section or "main"
                local section_table = self.sections[section]

                -- Loop through priority values in order
                for _, priority in ipairs(section_table.priorities) do
                    local priority_table = section_table[priority]

                    -- Loop through priority table
                    -- and call function on data table
                    for _, fn_table in ipairs(priority_table) do
                        fn(fn_table)
                    end
                end
            end

        }
    }

end)