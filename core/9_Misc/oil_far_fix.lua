table.insert(_rapi_initialize, function()
	local bOil = Buff.find("oil", "ror", true)
	local ignite_fix = AttackFlag.new(RAPI_NAMESPACE, "ChefIgniteFix")

	-- fix for oil jar explosions infinitely repeating
	Hook.add_pre(RAPI_NAMESPACE, gm.constants.damager_proc_onhitactor, function(self, other, result, args)
		local attack_info = AttackInfo.wrap(args[1].value.attack_info)
		
		if not attack_info:get_flag(AttackFlag.CHEF_IGNITE) then return end
		
		local target = Instance.wrap(args[1].value.target)
		local true_target = Instance.wrap(args[1].value.target_true)
		local parent = Instance.wrap(attack_info.parent)
		
		if attack_info:get_flag(AttackFlag.CHEF_IGNITE) then
			if target.object_index == gm.constants.oCrab and Instance.exists(parent) and parent.object_index == gm.constants.oP and parent.class == Survivor.find("chef").value then
				GM.achievement_progress_player(parent, 56, 1)
			end

			if target:buff_count(bOil) > 0 then
				target:buff_remove(bOil)
				local attack = GM.fire_explosion_noparent(true_target.x, true_target.y, attack_info.team, args[1].value.damage_true * 0.3, args[1].value.critical, gm.constants.sSparks12, gm.constants.sChefOilFire, 2.5, 5)
				attack.climb = 16.200000000000003
				attack.stun = 1
				attack.knockback_direction = attack_info.knockback_direction
				attack.proc = false
				
				self:create_networked_particles(true_target, 0)
			end
			
			attack_info:set_flag(AttackFlag.CHEF_IGNITE, false)
			attack_info:set_flag(ignite_fix, true)
		end
	end)

	Hook.add_post(RAPI_NAMESPACE, gm.constants.damager_proc_onhitactor, function(self, other, result, args)
		local attack_info = AttackInfo.wrap(args[1].value.attack_info)
		if not attack_info:get_flag(ignite_fix) then return end
		
		attack_info:set_flag(AttackFlag.CHEF_IGNITE, true)
		attack_info:set_flag(ignite_fix, false)
	end)
end)