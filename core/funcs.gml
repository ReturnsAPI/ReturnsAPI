
// this code should be fully DETERMINISTIC
// this is ran on the client that caused an attack INSTANTLY for fast feedback

function damager_calculate_damage(hit_info, true_hit, hit, damage, critical, parent, proc, attack_flags, damage_col, team, climb, percent_hp, xscale, hit_x, hit_y) {
	
	var damage_true, damage_fake
	damage_true = damage
	damage = damage_calculate_armor(damage, hit)
	damage_fake = round(damage * random_range(0.75, 1.25))
	
	// Sniper drone
	with (oSniperDrone) {
		if (tt = hit && !critical && parent == master) {
			damage *= 2
			critical = true
		}
	}
	//BLIND
	if (hit.buff_stack[BUFF_ID.blind]) {
		draw_damage(true_hit.x, true_hit.bbox_top - 16*GAME_SCALE, (ceil(damage * 1.25) - damage),
			false, C_DAMAGE_BLIND, team, climb)
		damage = ceil(damage * 1.25)
	}
	
	// THE TOXIN
	if (proc && hit.buff_stack[BUFF_ID.toxin]) {
		var multiplier = 1.15 + (0.15 * hit.buff_stack[BUFF_ID.toxin])
		
		draw_damage(true_hit.x, true_hit.bbox_top - 12*GAME_SCALE, ceil((damage * multiplier) - damage),
			false, C_DAMAGE_TOXIN, team, climb)
		
		if (G_QUALITY >= GRAPHICS_QUALITY.high){
			repeat(random_range(1,2)) {
				var t=random(360)
				part_type_direction(pBlood1, t - 10, t + 10, 0.1, 0)
				part_particles_create_color(above, hit_x, hit_y, pBlood1, c_lime, multiplier * 2)
			}
		}
		damage = ceil(damage * multiplier)
	}

	// % hp damage
	if (percent_hp != 0) {
		damage = max(damage, ceil(hit.hp * percent_hp * (critical?2:1)))
	}

	
	if (proc && instance_exists(parent))
	{
		// handle items that modify damage
		var t_inventory_item_stack = parent.inventory_item_stack
		
		// OL' LOPPER /////////////////////////////////////////////
		// part of this code is duplicated in damager_proc_onhitactor_clientandserver
		if (t_inventory_item_stack[ITEM_ID.the_ol_lopper]) {
			// make the hit critical
			var t = actor_get_hp_percent(hit)
			if (t < 1) {
				var dmg = 1 + (1-t) * t_inventory_item_stack[ITEM_ID.the_ol_lopper] * 0.6
				damage = ceil(damage * dmg)
				damage_true = ceil(damage_true * dmg)
				damage_fake = ceil(damage_fake * dmg)
			}
		}
		
		// CROWBAR ////////////////////////////////////////////////////
		if (t_inventory_item_stack[ITEM_ID.crowbar] && actor_get_hp_percent(hit) >= 0.8) {
			var dmg = 1.2 + t_inventory_item_stack[ITEM_ID.crowbar] * 0.3
			damage = ceil(damage * dmg)
			damage_true = ceil(damage_true * dmg)
			damage_fake = ceil(damage_fake * dmg)
	    
			with (instance_create(hit.x, hit.y, oEfSparks)) {
				sound_play(wCrowbar,1,random_range(0.8,1.1))
				sprite_index = sEfCrowbar
			}
		}
	
		// GOLDEN GUN /////////////////////////////////////////////////
		if (t_inventory_item_stack[ITEM_ID.golden_gun] > 0) {
			var dmg = min(1, (t_inventory_item_stack[ITEM_ID.golden_gun] * player_get_gold(parent) / (700 * power(_enemy_buff, SCALE_HP_COEFF))) * 0.4)
	    
			draw_damage_networked(true_hit.x - 16*GAME_SCALE, true_hit.bbox_top - 4*GAME_SCALE, ceil(damage * dmg),
				    critical, C_DAMAGE_GOLDGUN, team, climb)
	    
			damage = ceil(damage * (dmg + 1))
			damage_true = ceil(damage_true * (dmg + 1))
		}
	
		// LIZARD LOAF /////////////////////////////////////////////////
		if (t_inventory_item_stack[ITEM_ID.food_lizard]) {
			var dmg = ceil(damage_true * (t_inventory_item_stack[ITEM_ID.food_lizard] * 0.1 + 0.1))
			__item_lizard_loaf_proc_fx(true_hit, max(0, floor(climb * 0.5)), (xscale > 0), dmg, critical)
			damage += dmg
			damage_true += dmg
		}
		
		if (attack_flags & ATTACK_FLAG.knockback_proc_ef) {
			// deal extra damage
			draw_damage(hit.x, hit.y, ceil(damage), critical, C_DAMAGE_GLOVE, team, climb)
			damage = ceil(damage * 2)
			damage_true = ceil(damage_true * 2)
		}
	}
	
	
	// Damage numbers
	var xoff = 0
	if (damage_col == c_white && !proc) {
	    xoff = 12 * GAME_SCALE
	    damage_col = C_PROC
	}
	draw_damage(
		true_hit.x + xoff, true_hit.bbox_top - 4 * GAME_SCALE, 
		damage_fake,
		critical,
		damage_col,
		team,
		climb)
	
	
	// Store damage
	if (hit_info != undefined) {
		hit_info.damage_true = damage_true
		hit_info.damage = damage
		hit_info.damage_fake = damage_fake
		hit_info.critical = critical
	} else {
		global.__damager_calculate_damage__last_damage_value = damage
	}
	
	return critical
}

function _mod_instance_find(robj, rn) {
	switch object_get_type(robj) {
	    case OBJECT_TYPE.builtin:
		    return instance_find(robj, rn - 1)
    
	    case OBJECT_TYPE.custom:
		    var ii = 0;
		    with global.custom_object[robj-OBJECT_ID_CUSTOM_START, KEY_CUSTOM_OBJECT.base]
		        if __object_index = robj {
		            ii ++
		            if ii = rn {
		                return id
		            }
		        }
		    return noone        //No instance found
    
	    default:        //Nonexistant object or instance
		    return noone
	}



}

function _mod_instance_findAll(obj) {
	if obj >= OBJECT_ID_CUSTOM_START {
	    with (global.custom_object[obj - OBJECT_ID_CUSTOM_START, KEY_CUSTOM_OBJECT.base]) {
	        if (__object_index == obj) {
	            mod_push_value(id)
	        }
	    }
	} else {
	    with (obj) {
	        mod_push_value(id)
	    }
	}
}

// this is used when rendering ALL hp bars, not just the player hud bar
function hud_draw_health(_player, _col, _x, _y, _bar_w, _bar_h, _show_text, _flash_bar_col = undefined) {
	
	with _player {
		// red hud health /////////
		if (hud_hp_frame != current_frame) { // only update once per frame...
			if (hp >= hud_hp_last || current_frame > hud_hp_frame + 10) {
				hud_hp_last = hp
			} else {
				if (frameskip) {
					hud_hp_last = lerp(hud_hp_last, hp, 0.0975)
				} else {
					hud_hp_last = lerp(hud_hp_last, hp, 0.05)
				}
				if (hud_hp_last < hp + maxhp * 0.001) { hud_hp_last = hp }
			}
			hud_hp_frame = current_frame
		}
		
		var _hp_w = clamp(hp/maxhp, 0, 1)
	
		var _bar_w_hp = _bar_w
	
		if (_flash_bar_col == undefined) {
			// Shield
			if (maxshield != 0) {
				var _bar_w_shield = ceil(_bar_w_hp * (maxshield / (maxhp + maxshield)))
				_bar_w_hp -= _bar_w_shield
				var _shield_x = _x+ceil(_bar_w_hp*_hp_w)
				var _shield_w = ceil(_bar_w_shield*clamp(shield/maxshield,0,1))
				draw_sprite_stretched_ext(sHUDBarHP,0,_shield_x,_y,_shield_w,_bar_h,c_teal,1)
				if (_shield_w > 2) {
					draw_sprite_stretched_ext(sHUDBarHP,0,_shield_x+1,_y,_shield_w - 2,1,c_white,0.25)
				}
				if (_shield_w > 0) {
					draw_sprite_stretched_ext(sHUDBarHP,0,_shield_x,_y + 1, 1,_bar_h - 1,c_dkgray,0.35)
				}
			}
	
			// Last HP
			if (hud_hp_last > hp) {
				draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,ceil(_bar_w_hp*clamp(hud_hp_last/maxhp, 0, 1)),_bar_h, #CC0000, 1)
			}

			// Current HP
			_hp_w = ceil(_bar_w_hp*_hp_w)
			draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,_hp_w,_bar_h,_col,1)
			/*if (_hp_w > 2) {
				draw_sprite_stretched_ext(sHUDBarHP,0,_x + 1,_y,_hp_w - 2,1,c_white,0.4)
			}*/
			// Barrier
			if (barrier > 0) {
				gpu_set_colorwriteenable(1,1,1,0)
				gpu_set_blendmode(bm_add)
				draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,round(_bar_w*(barrier/ maxbarrier )),_bar_h,C_ORANGE,0.6)
				gpu_set_blendmode(bm_normal)
				gpu_set_colorwriteenable(1,1,1,1)
			}
		} else {
			// draw flashed bar
			// Shield
			if (maxshield != 0) {
				var _bar_w_shield = ceil(_bar_w_hp * (maxshield / (maxhp + maxshield)))
				_bar_w_hp -= _bar_w_shield
				var _shield_x = _x+ceil(_bar_w_hp*_hp_w)
				var _shield_w = ceil(_bar_w_shield*clamp(shield/maxshield,0,1))
				draw_sprite_stretched_ext(sHUDBarHP,0,_shield_x,_y,_shield_w,_bar_h,_flash_bar_col,1)
			}
			// Current HP
			_hp_w = ceil(_bar_w_hp*_hp_w)
			draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,_hp_w,_bar_h,_flash_bar_col,1)
			// Barrier
			if (barrier > 0) {
				draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,round(_bar_w*(barrier/ maxbarrier )),_bar_h,_flash_bar_col,0.6)
			}
		}
		
		if (_show_text) {
			if (invincible <= 1) {
			    // Show health number
			    draw_set_color(c_white)
			    draw_set_halign(fa_middle)
			    draw_set_valign(fa_middle)
			    __draw_set_font_RAW__(fntSquareSmall)
			    __draw_text_RAW__(_x + _bar_w div 2, _y + 4, string(ceil(clamp(hp, 0, maxhp)+clamp(shield, 0, maxshield)+barrier))+"/"+string(maxhp))
			} else if (invincible <= 1000) {
			    // "Immune"
				gpu_set_colorwriteenable(1,1,1,0)
			    draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,_bar_w,_bar_h,make_color_rgb(239,210,123),0.8)
				gpu_set_colorwriteenable(1,1,1,1)
			    draw_sprite(sImmune,0,_x + _bar_w div 2, _y + 5)
			} else {
			    // "Invincible"
				gpu_set_colorwriteenable(1,1,1,0)
			    draw_sprite_stretched_ext(sHUDBarHP,0,_x,_y,_bar_w,_bar_h,c_white,0.8)
				gpu_set_colorwriteenable(1,1,1,1)
			    draw_sprite(sImmune,1,_x + _bar_w div 2, _y + 5)
			}
		}
	}
	



}

// i would strongly recommend doing your own implementation of this using instance_place_list
// this implementation is very ineffecient
function lua_instance_place(argument0, argument1, argument2, argument3) {
	switch object_get_type(argument2) {
	    case OBJECT_TYPE.instance: case OBJECT_TYPE.builtin:
		    with argument0 return instance_place(argument0,argument1,argument2)
    
	    case OBJECT_TYPE.custom:
		    with global.custom_object[argument3 - OBJECT_ID_CUSTOM_START, KEY_CUSTOM_OBJECT.base]
		        if __object_index = argument2 && place_meeting(argument0,argument1,other) return id
		    return noone
    
	    default:        //None
		    return undefined
	}



}

// returns the nearest instance from an array of instance ids
function instance_nearest_array(xx, yy, arr) {
	var inst = noone, dist = infinity
	var i = 0 repeat (array_length(arr)) {
		with arr[i++] if (point_distance(x, y, xx, yy) < dist) {
			dist = point_distance(x, y, xx, yy)
			inst = id
		}
	}
	return inst
}

