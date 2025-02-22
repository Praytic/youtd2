extends ItemBehavior


var bestial_bt: BuffType


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_EXP_RECEIVED, -0.70, 0.0)
	modifier.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, -0.70, 0.0)


func item_init():
	bestial_bt = BuffType.create_aura_effect_type("bestial_bt", true, self)
	bestial_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	bestial_bt.set_buff_tooltip(tr("UEUU"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.12, 0.0024)
	mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.12, 0.0024)
	mod.add_modification(Modification.Type.MOD_DPS_ADD, 100, 6)
	bestial_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = bestial_bt
	item.add_aura(aura)
