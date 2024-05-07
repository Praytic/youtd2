extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_movespeed = 0.15, mod_movespeed_add = 0.004},
		2: {aura_range = 1100, mod_movespeed = 0.25, mod_movespeed_add = 0.006},
	}


func get_ability_info_list() -> Array[AbilityInfo]:
	var aura_range: String = Utils.format_float(_stats.aura_range, 2)
	var mod_movespeed: String = Utils.format_percent(_stats.mod_movespeed, 2)
	var mod_movespeed_add: String = Utils.format_percent(_stats.mod_movespeed_add, 2)

	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Frost Aura"
	ability.description_short = "Slows nearby creeps.\n"
	ability.description_full = "Slows movementspeed of enemies in %s range by %s.\n" % [aura_range, mod_movespeed] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s slow\n" % mod_movespeed_add
	list.append(ability)

	return list


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, 0.0, -0.001)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://Resources/Icons/GenericIcons/barefoot.tres")
	aura_bt.set_buff_tooltip("Frost Aura\nThis creep is under the effect of Frost Aura; it has reduced movement speed.")

	
func get_aura_types() -> Array[AuraType]:
	var aura_level: int = int(_stats.mod_movespeed * 1000)
	var aura_level_add: int = int(_stats.mod_movespeed_add * 1000)
	
	var aura: AuraType = AuraType.new()
	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = aura_level
	aura.level_add = aura_level_add
	aura.power = aura_level
	aura.power_add = aura_level_add
	aura.aura_effect = aura_bt
	return [aura]
