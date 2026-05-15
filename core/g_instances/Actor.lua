-- Actor

---@class Actor: Instance
Actor = new_class()
C.Actor = Actor


-- ========== Enums ==========

Actor.KnockbackKind = {
    NONE        = 0,    -- Does nothing; do not use
    STANDARD    = 1,    -- Applies stun; actor cannot move horizontally or act, but can jump
    FREEZE      = 2,    -- Frozen color shader vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    DEEPFREEZE  = 3,    -- Ice cube vfx; actor cannot move horizontally, but can jump and attack; actor also slides with less friction
    PULL        = 4,    -- STANDARD, but in the opposite direction
}


-- ========== Wrapper Methods ==========

---@class Actor
local methods = {}
G.methods_actor = methods

--[[
Kills the actor (synced).

**Must be called offline or as host.**
]]
methods.kill = function(self)
    self:actor_kill(self)
end