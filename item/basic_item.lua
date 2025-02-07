--- HYPOTHETICAL ITEM CREATION USING ReturnsAPI

local myItem = Item.new("myItem") -- namespace bound automatically

-- dedicated Sprite class -- not fully featured like RoRML's, but a bit prettier than a Resource class
-- path is relative to the mod's directory, rather than global like in RMT
myItem.sprite_id = Sprite.load("MyItem", "path/to/sprite.png", 1, 16, 16)
myItem:set_tier(Item.TIER.common)

local epic_sprite = Sprite.load("EpicDisplay", "path/to/epic.png", 10, 200, 200)
-- basic sprite display
myItem.effect_display = EffectDisplay.sprite(epic_sprite, ACTOR_DRAW_PRIORITY.above_body, 0.1, 0, 0)

-- more sophisticated
myItem.effect_display = EffectDisplay.func(function(actor, draw_x, draw_y)
	gm.draw_circle(draw_x, draw_y, 100, false)
end, ACTOR_DRAW_PRIORITY.above_body)
-- ^ can't assign more than one EffectDisplay at a time, but that's fine

-- scratch this. ActorComponents are difficult to use and not worth it. we are better off post-hooking step_actor and exposing an onStep thing as RMT does
--[[
-- onStep replacement
myItem.actor_component = ActorComponent.on_step(function(actor)
	-- ...
end)
--]]

-- sarn's suggestion. would require wrapping the callback ID fields, but the syntax seems nice
myItem.on_acquired:add(function(actor, stack)
	-- ...
end)
-- alternatively, but i think this is worse:
--Callback.add(myItem.on_acquire, function() ... end)

-- proc effect for myItem
Callback.onHitProc:add(function(attacker, victim, hit_info)
	-- potential awkwardness of abandoning class:onThing-style callbacks. but it does mean things can be less bloated
	-- if this isn't slow then i think it's perfectly OK
	local count = attacker:item_count(myItem)
	if count > 0 then
		-- ...
	end
end)

-- VERY HYPOTHETICAL. stat modification will require a dedicated API of some kind to handle everything behind the scenes.
-- this is a very loose idea vaguely based on R2API.RecalculateStats
RecalculateStats.add(function(actor, params)
	if actor:item_count(myItem) > 0 then
		params.damage_add = params.damage_add + 7
		params.maxhp_multiply = params.maxhp_multiply + 1
	end
end)

-- i propose something like this rather than making classes automatically create logbooks by default
-- this makes the API a bit more standardized, and doesn't hide as much from the user, which is a good thing imo
-- * .new() always just creates the thing with no extra side effects
-- * .new_from_<class>() can be provided if convenience is necessary
local myItemLog = ItemLog.new_from_item(myItem)

-- this seems like a saner API for achievement unlocks than having it be part of Item
local myItemAchievement = Achievement.new("unlockMyItem")
myItemAchievement:set_unlock_item(myItem)
