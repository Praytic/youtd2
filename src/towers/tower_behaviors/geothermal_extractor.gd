extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 200


func get_tier_stats() -> Dictionary:
	return {
		1: {damage_increase = 0.180, damage_increase_add = 0.005},
		2: {damage_increase = 0.300, damage_increase_add = 0.008},
	}


func tower_init():
	var m: Modifier = Modifier.new()
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	m.add_modification(Modification.Type.MOD_DAMAGE_ADD_PERC, 0.0, 1.0 / 10000)
	aura_bt.set_buff_modifier(m)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/angel_outfit.tres")
	aura_bt.set_buff_tooltip("Thermal Boost\nIncreases attack damage.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	var damage_increase: String = Utils.format_percent(_stats.damage_increase, 2)
	var damage_increase_add: String = Utils.format_percent(_stats.damage_increase_add, 2)

	aura.name = "Thermal Boost"
	aura.icon = "res://resources/icons/tower_variations/mossy_acid_sprayer_red.tres"
	aura.description_short = "Increases attack damage of nearby towers.\n"
	aura.description_full = "Increases attack damage of towers in %d range by %s.\n" % [AURA_RANGE, damage_increase] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s damage\n" % damage_increase_add

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = int(_stats.damage_increase * 10000)
	aura.level_add = int(_stats.damage_increase_add * 10000)
	aura.power = int(_stats.damage_increase * 10000)
	aura.power_add = int(_stats.damage_increase_add * 10000)
	aura.aura_effect = aura_bt
	return [aura]
