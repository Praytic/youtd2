extends ItemBehavior


var rot_bt: BuffType


func item_init():
	rot_bt = BuffType.create_aura_effect_type("rot_bt", true, self)
	rot_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	rot_bt.set_buff_tooltip(tr("RI8B"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, 0.12, 0.0024)
	rot_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = rot_bt
	item.add_aura(aura)
