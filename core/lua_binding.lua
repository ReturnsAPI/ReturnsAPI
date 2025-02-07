-- SAMPLE OF CODE FOR BINDING LUA FUNCTIONS TO GAMEMAKER CSCRIPTREFS
-- ReturnsAPI will need to implement this internally for various things

-- NOTE: this file is intended to be run after game initialization, not directly from main.lua

if ref_list then
	-- basic live loading handler
	gm.ds_list_destroy(ref_list) -- this results in unreferenced structs and CScriptRefs getting garbage collected
	log.debug("destroying previous ref_list...")
end
ref_list = gm.ds_list_create()
log.debug("creating ref_list")

local id_count = 0
local id_to_func = {}

local STRUCT_METHOD_ID_KEY = "__id"

--- this function takes a lua function and uses black magic to wrap it in a CScriptRef which you can give to things that accept a gamemaker function
function bind_function(func)
	log.debug(string.format("binding method id: %i", id_count))

	local struct = gm.struct_create()
	gm.variable_struct_set(struct, STRUCT_METHOD_ID_KEY, id_count)

	id_to_func[id_count] = func
	id_count = id_count + 1
	-- bind a struct to a dummy function, so the struct is the self when this CScriptRef is executed
	local method = gm.method(struct, gm.constants.function_dummy)

	-- gamemaker has a garbage collector that will send any unreferenced structs, arrays, and CScriptRefs to the shadow realm.
	-- DS lists and maps are not garbage collected, so one is used here to maintain a reference to the CScriptRef
	gm.ds_list_add(ref_list, method)

	-- NOTE for ReturnsAPI: this ref_list and id mapping system should be made more sophisticated to accommodate our goals for live loading

	return method
end

-- LIMITATIONS:
-- * If `method` is called internally against your bound CScriptRef, then the `self` argument will no longer be the custom struct, therefore stopping it from being recognized by the hook
-- * If the given function call relies on accessing `self` to be useful, then it likely won't be useful from this context

gm.post_script_hook(gm.constants.function_dummy, function(self, other, result, args)
	if gm.is_struct(self) then
		local fn = id_to_func[gm.variable_struct_get(self, STRUCT_METHOD_ID_KEY)]
		if fn then
			local arg_table = {}
			for i=1, #args do
				table.insert(arg_table, args[i].value)
			end
			local ret = fn(table.unpack(arg_table))
			if ret then result.value = ret end
		end
	end
end)



------------------------------------------------
-- EXAMPLES
------------------------------------------------
-- EffectDisplay assigned to an item
------------------------------------------------

-- EffectDisplays are the main system used by the game to draw item and buff effects.
-- there are a number of them in the game, the one used here is EffectDisplayFunction as it previously couldn't be used, and is the most versatile
-- a big benefit of using EffectDisplay over just hooking draw_actor is that you get to specifiy a "priority", which determines the order relative to other EffectDisplays that yours gets drawn in. higher is drawn later

local test_display = bind_function(function(instance, x, y)
	gm.draw_circle(x, y, 40 + math.sin(gm.variable_global_get("_current_frame") * 0.1) * 8, true)
end)

-- `10` is the priority, making it draw behind the player. numbers > 0 draw below, <= 0 draw above.
local effect_display = gm["@@NewGMLObject@@"](gm.constants.EffectDisplayFunction, test_display, 10)
gm.ds_list_add(ref_list, effect_display) -- not necessary if you're adding it to an item/buff, as that counts as a reference -- but it's probably good to have as a safety measure anyhow

-- find the item and its array
local CLASS_ITEM = gm.variable_global_get("class_item")
local item_id = gm.item_find("guardiansHeart")
local item_array = gm.array_get(CLASS_ITEM, item_id)

-- set the item's effect_display field to our EffectDisplay
gm.array_set(item_array, 12, effect_display)

------------------------------------------------
-- GenericCallable assigned to bullet attacks' on_hit InstanceCallback, spawning chain lightning on all bullet attack hits
------------------------------------------------

local on_hit_lightning = gm.callable_function(bind_function(function(obj, hit, x, y)
	local l = gm.instance_create(x, y, gm.constants.oChainLightning)
	l.parent = obj.attack_info.parent
	l.team = obj.attack_info.team
	l.damage = obj.attack_info.damage
end))
gm.ds_list_add(ref_list, on_hit_lightning)

gm.post_code_execute("gml_Object_pAttack_Create_0", function(self, other)
	if self.object_index ~= gm.constants.oBulletAttack then return end
	gm.array_push(self.on_hit.callables, on_hit_lightning)

	--gm.instance_callback_set(self.on_hit, t) -- DOES NOT WORK because it calls method(undefined, func) internally, breaking this hooking system
end)
