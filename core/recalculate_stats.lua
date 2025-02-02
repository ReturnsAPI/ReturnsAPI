
local __mt = {
	__index = function(self, field)
		return gm.variable_struct_get(self.value, field)
	end,
	__newindex = function(self, field, value)
		gm.variable_struct_set(self.value, field, value)
	end,
}

local function wrap(struct)
	return setmetatable({value = struct}, __mt)
end

-- helpful constants
local SCALE_ELITE_HP       = 2.8
local SCALE_ELITE_HP_HONOR = 2.2
local SCALE_ELITE_DAMAGE   = 1.9
local SCALE_ELITE_HP_BOSS  = 2.1
local SCALE_ELITE_DAMAGE_BOSS = 1.3
local SCALE_BLIGHT_HP      = 7
local SCALE_BLIGHT_DAMAGE  = 3.2

local ITEM_ID = {
	lens_makers_glasses = 3,
	mysterious_vial = 9,
	pauls_goat_hoof = 17,
	bitter_root = 18,
	soldiers_syringe = 20,
	snake_eyes = 21,
	infusion = 27,
	mocha = 89,
	tough_times = 30,
	energy_cell = 31,
	rusty_jetpack = 32,
	leeching_seed = 33,
	ukulele = 34,
	guardians_heart = 37,
	red_whip = 40,
	harvesters_scythe = 49,
	predatory_instincts = 51,
	rapid_mitosis = 61,
	brilliant_behemoth = 64,
	wicked_ring = 67,
	firemans_boots = 74,
	colossal_knurl = 81,
	white_undershirt = 83,
	small_enigma = 85,
	aegis = 92,
	arcane_blades = 97,
	scorching_shell_piece = 98,
	razor_penny = 100,
	food_golem = 110,
	food_bison = 112,
	elite_orb_explosive_shot = 115,
	elite_orb_attack_speed = 116,
	elite_orb_fire_trail = 117,
	elite_orb_move_speed = 118,
	elite_orb_lightning = 119,
	elite_orb_lifesteal = 120,
	glass_stat_handler = 125,
	drizzle_stat_handler = 126,
	distortion_stat_handler = 127,
	ghost_stat_handler = 128,
	imp_tentacle_imp_stat_handler = 130,
	hit_list_tally = 132,
}
local BUFF_ID = {
	worm_eye = 0,
	slow = 1,
	burst_speed = 2,
	slow2 = 5,
	shield = 6,
	thallium = 7,
	warbanner = 8,
	dice = 9,
	snare = 10,
	dash = 11,
	poison_speed_boost = 13,
	sunder = 14,
	blood = 15,
	attack_speed = 16,
	super_shield = 17,
	oil = 18,
	reflecting = 22,
	pills = 27,
	leech = 28,
	overclock = 30,
	scavenger_boost = 31,
	smokebomb = 32,
	loader_shield = 33,
	red_whip = 34,
	bandit_skull = 36,
	blind = 37,
	drone_speed = 38,
	loader_speed_2 = 39,
	arcane_blades = 41,
	medallion = 43,
	slow_goop = 46,
	harpoon = 47,
	rained = 50,
	drone_empower = 51,
	imp_eye = 54,
}
local ARTIFACT_ID = {
	honor = 0,
	spirit = 8,
}
local CLASS_ARTIFACT = {
	is_active = 8,
}
local ARTIFACT = gm.variable_global_get("class_artifact")

-- recreation of recalculate_stats for the purposes of properly injecting custom modifiers
function recalculate_stats(actor)
	--log.debug(string.format("custom recalculate_stats called on %s", gm.object_get_name(actor.object_index)))

	-- somewhere here, before anything else happens, we would fetch all the custom params from the RecalculateStats API
	-- then we would apply them throughout this function as needed
	-- this means that mod code no longer touches recalculate_stats or actor variables directly, letting things be handled nicely

	local _level = actor.level - 1
	local _is_boss = gm.actor_is_boss(actor.value)
	local _is_player = actor.object_index == gm.constants.oP

	local _item_stack = actor.inventory_item_stack
	local _buff_stack = actor.buff_stack

	local _maxhp_old = actor.maxhp

	-- intermediate table used for every variable, which all get written back to the actor near the end of the function.
	-- don't know if it's actually necesssary, but it reduces gm calls, and we're trying to optimize for that, so...?
	local stats = {
		hud_health_color = 0x4CC9DB,
		knockback_cap = actor.knockback_cap_base,

		damage = actor.damage_base + actor.damage_level * _level,
		attack_speed = actor.attack_speed_base + actor.attack_speed_level * _level,
		critical_chance = actor.critical_chance_base + actor.critical_chance_level * _level,

		maxhp = actor.maxhp_base + actor.maxhp_level * _level,
		hp_regen = actor.hp_regen_base + actor.hp_regen_level * _level,
		armor = actor.armor_base + actor.armor_level * _level,

		maxshield = actor.maxshield_base,

		pHmax = actor.pHmax_base,
		pVmax = actor.pVmax_base,
		pGravity1 = actor.pGravity1_base,
		pGravity2 = actor.pGravity2_base,
		pAccel = actor.pAccel_base,
		knockback_cap = actor.knockback_cap_base,

		cdr = 0,

		lifesteal = 0,
	}

	if actor.object_index == gm.constants.oPDrone then
		stats.hud_health_color = 0xF2A282
	elseif gm.object_is_ancestor(actor.object_index, gm.constants.pFriend) == 1 then
		stats.hud_health_color = 0x67D388
	end

	-- additive modifiers
	-- good place for custom additive maxhp modifiers
	stats.maxhp = stats.maxhp + actor.infusion_hp
				+ gm.array_get(_item_stack, ITEM_ID.colossal_knurl) * 40
				+ gm.array_get(_item_stack, ITEM_ID.drizzle_stat_handler) * 50

	-- multiplicative modifiers
	-- good place for custom multiplicative maxhp modifiers
	stats.maxhp = stats.maxhp * (1 + gm.array_get(_item_stack, ITEM_ID.bitter_root) * 0.08)

	-- vanilla applies the cap before elite and other misc multipliers, so that's preserved here
	stats.maxhp = math.min(stats.maxhp, actor.maxhp_cap)

	-- Elite effects
	if actor.elite_type == 6 then -- ELITE_TYPE_ID.blighted
	    stats.cdr = stats.cdr + (1 - stats.cdr) * 0.5
	    stats.knockback_cap = stats.knockback_cap * 15
	    stats.maxhp = stats.maxhp * SCALE_BLIGHT_HP
	    stats.damage = stats.damage * SCALE_BLIGHT_DAMAGE
	elseif actor.elite_type ~= -1 then
	    stats.knockback_cap = stats.knockback_cap * 3
	    stats.cdr = stats.cdr + (1 - stats.cdr) * 0.3
	    if _is_boss then
	        stats.maxhp = stats.maxhp * SCALE_ELITE_HP_BOSS
	        stats.damage = stats.damage * SCALE_ELITE_DAMAGE_BOSS
	    else
			if gm.array_get(gm.array_get(ARTIFACT, ARTIFACT_ID.honor), CLASS_ARTIFACT.is_active) then
				stats.maxhp = stats.maxhp * SCALE_ELITE_HP_HONOR
			else
				stats.maxhp = stats.maxhp * SCALE_ELITE_HP
			end
	        stats.damage = stats.damage * SCALE_ELITE_DAMAGE
	    end
	end

	if gm.array_get(_item_stack, ITEM_ID.distortion_stat_handler) > 0 then
	    stats.cdr = stats.cdr + (1 - stats.cdr) * 0.25
	end

	-- probably a good place for custom additive damage modifiers?
	stats.damage = stats.damage + gm.array_get(_item_stack, ITEM_ID.hit_list_tally) * 0.5
								+ gm.array_get(_buff_stack, BUFF_ID.warbanner) * 4
								+ gm.array_get(_buff_stack, BUFF_ID.medallion) * 1

	stats.damage = stats.damage * 1 + 0.3 * gm.array_get(_buff_stack, BUFF_ID.pills)

	local _ghost_stat_handler = gm.array_get(_item_stack, ITEM_ID.ghost_stat_handler)
	if _ghost_stat_handler > 0 then
	    stats.damage = stats.damage * 0.4 + _ghost_stat_handler * 0.3
	    stats.maxhp = stats.maxhp * 0.8 + _ghost_stat_handler * 0.2
	end
	if gm.array_get(_buff_stack, BUFF_ID.rained) > 0 then
	    stats.damage = stats.damage * 0.75
	end


	if gm.array_get(_item_stack, ITEM_ID.glass_stat_handler) > 0 then
		-- apply glass modifier
	    stats.maxhp = stats.maxhp * 0.1
	    stats.damage = stats.damage * 5
	    -- glass hp colour
	    stats.hud_health_color = 0xC974AF
	end

	local _imp_tentacle_imp_stat_handler = gm.array_get(_item_stack, ITEM_ID.imp_tentacle_imp_stat_handler)
	if _imp_tentacle_imp_stat_handler > 0 then
		stats.maxhp = stats.maxhp * 1 + _imp_tentacle_imp_stat_handler * 0.15
		stats.damage = stats.damage * 1 + _imp_tentacle_imp_stat_handler * 0.15
	end

	local _bandit_skull = gm.array_get(_buff_stack, BUFF_ID.bandit_skull)
	if _bandit_skull > 0 then
		stats.damage = stats.damage * 1 + 0.25 * _bandit_skull
	end
	if gm.array_get(_item_stack, ITEM_ID.infusion) > 0 then
	    -- infusion hp colour
	    stats.hud_health_color = 0x423FA9
	end

	-- here would be a good place for applying custom hud_health_color
	-- UNLESS you want it to override the enemy party hp colour, in which case do it way below

	if _is_player and actor.balance_config then
		stats.damage = stats.damage * gm.variable_struct_get(actor.balance_config, "multiplier_damage_dealt")
	end

	-- Calculate shield
	local _maxshield_old = actor.maxshield
	stats.maxshield = stats.maxshield + gm.array_get(_item_stack, ITEM_ID.guardians_heart) * 60
									+ gm.array_get(_item_stack, ITEM_ID.scorching_shell_piece) * 20

	-- finalize hp
	-- TODO: see about preventing the HUD health bar from interpreting maxhp loss as damage and incorrectly doing the damage effects
	-- vanilla doesn't do that but we should implement it for QoL
	stats.maxhp = math.max(1, math.ceil(stats.maxhp))
	stats.hp = math.min(stats.maxhp, actor.hp + math.max(0, stats.maxhp - _maxhp_old))

	stats.maxshield = math.ceil(stats.maxshield)
	stats.shield = math.min(stats.maxshield, actor.shield + math.max(0, stats.maxshield - _maxshield_old))

	if (_maxshield_old == 0) ~= (stats.maxshield == 0) then
		-- update shield display
		if stats.maxshield == 0 then
			gm.actor_drawscript_remove(actor.value, gm.variable_global_get("DrawScript_shield"))
		else
			gm.actor_drawscript_attach(actor.value, gm.variable_global_get("DrawScript_shield"))
		end
	end

	-- additive hp regen
	stats.hp_regen = stats.hp_regen + gm.array_get(_item_stack, ITEM_ID.mysterious_vial) * 0.014
									+ gm.array_get(_item_stack, ITEM_ID.colossal_knurl) * 0.02
									+ gm.array_get(_item_stack, ITEM_ID.drizzle_stat_handler) * 0.03
									+ gm.array_get(_buff_stack, BUFF_ID.medallion) * 0.006
									+ gm.array_get(_item_stack, ITEM_ID.food_bison) * 0.006

	-- additive crit chance
	stats.critical_chance = stats.critical_chance + gm.array_get(_item_stack, ITEM_ID.lens_makers_glasses ) * 8
												+ gm.array_get(_item_stack, ITEM_ID.razor_penny ) * 4

	if gm.array_get(_item_stack, ITEM_ID.harvesters_scythe) > 0 then
		stats.critical_chance = stats.critical_chance + 5
	end
	if gm.array_get(_item_stack, ITEM_ID.predatory_instincts) > 0 then
		stats.critical_chance = stats.critical_chance + 5
	end

	local _wicked_ring = gm.array_get(_item_stack, ITEM_ID.wicked_ring)
	if _wicked_ring > 0 then
		stats.critical_chance = stats.critical_chance + 5 + (10 * (_wicked_ring - 1))
	end

	local _dice = gm.array_get(_buff_stack, BUFF_ID.dice)
	if _dice > 0 then
		stats.critical_chance = stats.critical_chance + (7 * gm.array_get(_item_stack, ITEM_ID.snake_eyes )) * _dice
	end

	-- multiplicative crit chance here i guess? idk

	-- Calculate lifesteal
	stats.lifesteal = stats.lifesteal + gm.array_get(_item_stack, ITEM_ID.leeching_seed)
									+ gm.array_get(_item_stack, ITEM_ID.elite_orb_lifesteal) * 5
									+ gm.array_get(_buff_stack, BUFF_ID.leech) * 9

	-- Calculate base attack speed
	stats.attack_speed = stats.attack_speed + gm.array_get(_item_stack, ITEM_ID.soldiers_syringe ) * 0.12
						+ gm.array_get(_item_stack, ITEM_ID.mocha ) * 0.06
						+ gm.array_get(_item_stack, ITEM_ID.elite_orb_attack_speed ) * 0.1
						+ gm.array_get(_buff_stack, BUFF_ID.medallion ) * 0.06
						+ gm.array_get(_buff_stack, BUFF_ID.drone_empower ) * 0.7
						-- 40% ups
						+ ( gm.array_get(_buff_stack, BUFF_ID.attack_speed )
						+ gm.array_get(_buff_stack, BUFF_ID.pills )
						+ gm.array_get(_buff_stack, BUFF_ID.scavenger_boost )) * 0.4
						-- 30% ups
						+ ( gm.array_get(_buff_stack, BUFF_ID.warbanner )
						+ gm.array_get(_buff_stack, BUFF_ID.super_shield )
						+ gm.array_get(_buff_stack, BUFF_ID.overclock )) * 0.3
						-- pred
						+ gm.array_get(_buff_stack, BUFF_ID.blood ) * (0.03 + gm.array_get(_item_stack, ITEM_ID.predatory_instincts ) * 0.07)
						+ gm.array_get(_buff_stack, BUFF_ID.drone_speed ) *0.10
						-- loader alt special
						+ gm.array_get(_buff_stack, BUFF_ID.loader_speed_2 )*0.6

	local _energy_cell = gm.array_get(_item_stack, ITEM_ID.energy_cell )
	if _energy_cell > 0 then
	    -- Energy cell, increase attack speed as HP gets lower
	    stats.attack_speed = stats.attack_speed + (0.1 + gm.array_get(_item_stack, ITEM_ID.energy_cell ) * 0.3)*(1-((actor.hp + actor.shield) / (actor.maxhp + actor.maxshield)))
	end

	-- Calculate base speed
	stats.pHmax = stats.pHmax + gm.array_get(_item_stack, ITEM_ID.pauls_goat_hoof ) * (0.3)
							+ gm.array_get(_item_stack, ITEM_ID.mocha           ) * (0.15)
							+ gm.array_get(_item_stack, ITEM_ID.food_bison ) * 0.2
							- gm.sign(actor.bunker) * 0.7

	stats.pHmax = stats.pHmax * (1 + gm.array_get(_item_stack, ITEM_ID.elite_orb_move_speed) * 0.05
	            + gm.array_get(_buff_stack, BUFF_ID.loader_shield ) * 0.2)


	stats.pHmax = stats.pHmax + gm.array_get(_buff_stack, BUFF_ID.worm_eye )  * 0.6
	        + gm.array_get(_buff_stack, BUFF_ID.warbanner ) * 0.6
	        + gm.array_get(_buff_stack, BUFF_ID.poison_speed_boost ) * 0.8
	        + gm.array_get(_buff_stack, BUFF_ID.smokebomb ) * 1
			- gm.array_get(_buff_stack, BUFF_ID.blind ) * 1
	        + gm.array_get(_buff_stack, BUFF_ID.dash )  * 20
	        + gm.array_get(_buff_stack, BUFF_ID.red_whip ) * gm.array_get(_item_stack, ITEM_ID.red_whip ) * 1.2
			+ gm.array_get(_buff_stack, BUFF_ID.medallion ) * 0.2
			+ gm.array_get(_buff_stack, BUFF_ID.arcane_blades ) * gm.array_get(_item_stack, ITEM_ID.arcane_blades ) * 0.6
			+ gm.array_get(_buff_stack, BUFF_ID.overclock ) * 0.15

	if gm.array_get(_buff_stack, BUFF_ID.harpoon ) ~= 0 then
		stats.pHmax = stats.pHmax + 1.25
	end

	local _burst_speed = gm.array_get(_buff_stack, BUFF_ID.burst_speed )
	if _burst_speed > 0 then
	    stats.pHmax = stats.pHmax + math.min(_burst_speed / 60, 1)
	end

	-- Apply speed debuffs
	if not gm.bool(actor.stun_immune) then
	     stats.pHmax = stats.pHmax - (gm.array_get(_buff_stack, BUFF_ID.slow ) * 1
		        + gm.array_get(_buff_stack, BUFF_ID.slow_goop ) * 1
	            + gm.array_get(_buff_stack, BUFF_ID.slow2 ) * 1.6
	            + gm.array_get(_buff_stack, BUFF_ID.snare ) * 400
	            + gm.array_get(_buff_stack, BUFF_ID.oil )   * 0.8)

	    if gm.array_get(_buff_stack, BUFF_ID.thallium ) > 0 then
	         stats.pHmax = stats.pHmax - 3 * (gm.array_get(_buff_stack, BUFF_ID.thallium ) / 180)
	    end
	end

	-- good place for custom speed modifiers?

	if gm.array_get(_buff_stack, BUFF_ID.imp_eye ) > 0 then
		stats.pHmax = stats.pHmax * 0.625
		stats.attack_speed = stats.attack_speed * 0.75
	end

	-- pHmax_raw is used by artifact of spirit to remember the raw value -- it calculates pHmax from this value
	stats.pHmax_raw = math.max(0, stats.pHmax)
	stats.pHmax = stats.pHmax_raw
	if gm.array_get(gm.array_get(ARTIFACT, ARTIFACT_ID.spirit), CLASS_ARTIFACT.is_active) then
		stats.pHmax = stats.pHmax_raw * 1 + math.max(0,(2*(1-(actor.hp/actor.maxhp))))
	end


	-- additive armor modifiers
	stats.armor = stats.armor + gm.array_get(_item_stack, ITEM_ID.colossal_knurl )   * 6
							+ gm.array_get(_item_stack, ITEM_ID.tough_times )      * 14
							+ gm.array_get(_item_stack, ITEM_ID.white_undershirt ) * 3
							+ gm.array_get(_buff_stack, BUFF_ID.shield ) * 100
							- gm.array_get(_buff_stack, BUFF_ID.sunder ) * 6
							+ gm.array_get(_buff_stack, BUFF_ID.super_shield ) * 999999
							+ gm.array_get(_buff_stack, BUFF_ID.reflecting ) * 1000
							- gm.array_get(_buff_stack, BUFF_ID.rained ) * 30

	local _food_golem = gm.array_get(_item_stack, ITEM_ID.food_golem)
	if _food_golem > 0 then
		stats.armor = stats.armor + 30 + 10 * _food_golem
	end

	-- Misc stats

	stats.explosive_shot = gm.array_get(_item_stack, ITEM_ID.brilliant_behemoth )
						+ gm.array_get(_item_stack, ITEM_ID.elite_orb_explosive_shot )

	stats.lightning = gm.array_get(_item_stack, ITEM_ID.ukulele ) * 2
					+ gm.array_get(_item_stack, ITEM_ID.elite_orb_lightning )

	stats.fire_trail = gm.array_get(_item_stack, ITEM_ID.firemans_boots )
					+ gm.array_get(_item_stack, ITEM_ID.elite_orb_fire_trail ) * 0.1
					+ gm.array_get(_buff_stack, BUFF_ID.worm_eye ) * 0.5

	local _equipment_cdr_old = actor.equipment_cdr

	stats.equipment_cdr = 1 - 1
				    * math.pow(0.75, gm.array_get(_item_stack, ITEM_ID.rapid_mitosis ))
				    * math.pow(0.95, gm.array_get(_item_stack, ITEM_ID.small_enigma ))

	local _alarm_0 = gm.call("alarm_get", actor.value, actor.value, 0)
	if (_is_player and _alarm_0 ~= -1 and stats.equipment_cdr ~= _equipment_cdr_old) then
		-- scale remaining cooldown off of new cdr
		_alarm_0 = _alarm_0 * (1 - equipment_cdr) / (1 - _equipment_cdr_old)
	end
	gm.call("alarm_set", actor.value, actor.value, 0,  _alarm_0)

	stats.pAccel = stats.pAccel / (0.9 + stats.pHmax * 0.05)
	stats.pFriction = actor.pAccel_base * (2.5 + stats.pHmax) / 2
	if gm.array_get(_item_stack, ITEM_ID.rusty_jetpack) > 0 then
		stats.pGravity2 = math.min(stats.pGravity2, gm.lerp(stats.pGravity2, 0.1, 1 - math.pow(0.9, gm.array_get(_item_stack, ITEM_ID.rusty_jetpack ))))
		stats.pVmax = stats.pVmax + gm.log2(gm.array_get(_item_stack, ITEM_ID.rusty_jetpack ) + 1) * 1.2
	end

	stats.maxbarrier = (stats.maxhp + stats.maxshield) * (1 + gm.array_get(_item_stack, ITEM_ID.aegis) * 0.2)
	actor.barrier = math.min(actor.barrier, stats.maxbarrier)

	-- write everything back into the instance
	for stat, value in pairs(stats) do
		actor[stat] = value
	end

	-- actor skills depend on the cdr and atk speed stats, so update them after stats have been written back
	for i=0, 3 do
		-- ActorSkillSlot.skill_recalculate_stats calls active_skill.skill_recalculate_stats internally
		-- it also gets automatically called when the active ActorSkill changes, so it needs independent handling
		local slot = wrap(gm.array_get(actor.skills, i))
		slot.skill_recalculate_stats(slot.value, slot.value)
	end

	-- if we're a member of an actor party (HUD boss group)
	if actor.enemy_party then
		--inherit the party's health colour
		hud_health_color = gm.variable_struct_get(actor.enemy_party, "health_colour")
		--update the party's stats for this actor
		actor.enemy_party.actor_stats_update(actor.enemy_party, actor.enemy_party, actor.id)
	end

	-- ACTOR_COMPONENT_SCRIPT_KIND.modify_stats
	-- not sure if this is the best place to execute this but vanilla does it here so
	gm.call("actor_script_execute", actor.value, actor.value, 1)

	actor.stats_dirty = false
end

gm.pre_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
	recalculate_stats(wrap(self))
	return false
end)

local ActorSkill_recalculate_stats = gm.constants.anon_ActorSkill_gml_GlobalScript_scr_actor_skills_83921016_ActorSkill_gml_GlobalScript_scr_actor_skills

gm.post_script_hook(ActorSkill_recalculate_stats, function(self, other, result, args)
	local actor_skill = wrap(self)

	-- TODO
end)
