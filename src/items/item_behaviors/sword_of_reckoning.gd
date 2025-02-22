extends ItemBehavior


var holy_wrath_bt: BuffType


func item_init():
	holy_wrath_bt = BuffType.create_aura_effect_type("holy_wrath_bt", true, self)
	holy_wrath_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	holy_wrath_bt.set_buff_tooltip(tr("8CD3"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.12, 0.0024)
	holy_wrath_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = holy_wrath_bt
	item.add_aura(aura)
