extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 200


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MULTICRIT_COUNT, 2, 0.0)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/biceps.tres")
	aura_bt.set_buff_tooltip(tr("RGO6"))
