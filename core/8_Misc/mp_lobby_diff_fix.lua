-- Multiplayer Lobby Difficulty Fix
-- by Kris

memory.dynamic_hook("RAPI.Fix.game_lobby_start", "void*", {"void*", "void*", "void*", "int", "void*"}, gm.get_script_function_address(gm.constants.game_lobby_start),
    -- Pre-hook
    {nil,

    -- Post-hook
    function(ret_val, self, other, result, arg_count, args)
        local vote_count = Global.__game_lobby.rulebook.vote_count
        local diff_count = Global.count_difficulty
        for i = 11, diff_count do
            vote_count["d:"..tostring(i)] = 0
        end
    end}
)