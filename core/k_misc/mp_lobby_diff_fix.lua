-- Multiplayer Lobby Difficulty Fix
-- by Kris

gm.post_script_hook(gm.constants.game_lobby_start, function(self, other, result, args)
    local vote_count = Global.__game_lobby.rulebook.vote_count
    local diff_count = Global.count_difficulty
    for i = 11, diff_count do
        vote_count["d:"..tostring(i)] = 0
    end
end)