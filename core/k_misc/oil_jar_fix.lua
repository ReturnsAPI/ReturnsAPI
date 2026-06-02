-- Fix for oil jar explosions infinitely repeating

local Instance_exists = Instance.exists
local AttackInfo_wrap = AttackInfo.wrap
local ach_prog_player = gm.achievement_progress_player  ---@type function
local fire_expl_nopar = gm.fire_explosion_noparent      ---@type function

local chef_ignite = AttackFlag.CHEF_IGNITE
local sparks12    = gm.constants.sSparks12      ---@type number
local chefoilfire = gm.constants.sChefOilFire   ---@type number

run_on_initialize(function()
	local bOil = Buff.find("oil", "ror", true)
	local ignite_fix = AttackFlag.new(RAPI_NAMESPACE, "ChefIgniteFix")
    local chef_class_id = Survivor.find("chef", "ror", true).value

	Hook.add_pre(RAPI_NAMESPACE, gm.constants.damager_proc_onhitactor, function(self, other, result, args)
		local struct = args[1].value ---@type Struct
        local attack_info = AttackInfo_wrap(struct.attack_info)
		
		if not attack_info:get_flag(chef_ignite) then return end
		
		local target 	  = struct.target      ---@type Actor
		local true_target = struct.target_true ---@type Actor
		local parent      = attack_info.parent  ---@type Actor
		
		if  target.object_index == gm.constants.oCrab
		and Instance_exists(parent)
		and parent.object_index == gm.constants.oP
		and parent.class == chef_class_id then
			ach_prog_player(parent, 56, 1)
		end

		if target:buff_count(bOil) > 0 then
			target:buff_remove(bOil)
			local attack = fire_expl_nopar(
				true_target.x,
				true_target.y,
				attack_info.team,
				struct.damage_true * 0.3,
				struct.critical,
				sparks12,
				chefoilfire,
				2.5,
				5
			)
			attack.climb = 16.200000000000003
			attack.stun = 1
			attack.knockback_direction = attack_info.knockback_direction
			attack.proc = false
			
			self:create_networked_particles(true_target, 0)
		end
		
		attack_info:set_flag(chef_ignite, false)
		attack_info:set_flag(ignite_fix, true)
	end)

	Hook.add_post(RAPI_NAMESPACE, gm.constants.damager_proc_onhitactor, function(self, other, result, args)
        local attack_info = AttackInfo_wrap(args[1].value.attack_info)
		if not attack_info:get_flag(ignite_fix) then return end
		
		attack_info:set_flag(chef_ignite, true)
		attack_info:set_flag(ignite_fix, false)
	end)
end)