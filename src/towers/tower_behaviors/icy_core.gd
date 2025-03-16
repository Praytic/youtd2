extends TowerBehavior


var aura_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {aura_range = 800, mod_movespeed = 0.15, mod_movespeed_add = 0.004},
		2: {aura_range = 1100, mod_movespeed = 0.25, mod_movespeed_add = 0.006},
	}


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.mod_movespeed, -_stats.mod_movespeed_add)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/barefoot.tres")
	aura_bt.set_buff_tooltip("Frost Aura\nReduces movement speed.")

	
func get_aura_types_DELETEME() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var mod_movespeed: String = Utils.format_percent(_stats.mod_movespeed, 2)
	var mod_movespeed_add: String = Utils.format_percent(_stats.mod_movespeed_add, 2)

	aura.name = "Frost"
	aura.icon = "res://resources/icons/orbs/orb_ice.tres"
	aura.description_short = "Slows nearby creeps.\n"
	aura.description_full = "Slows creeps in %d range by %s.\n" % [_stats.aura_range, mod_movespeed] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s slow\n" % mod_movespeed_add

	aura.aura_range = _stats.aura_range
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]
