extends TowerBehavior


var aura_bt: BuffType


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.15, 0.004)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/polar_star.tres")
	aura_bt.set_buff_tooltip("Dwarven Polish Aura\nIncreases quality of dropped items.")
