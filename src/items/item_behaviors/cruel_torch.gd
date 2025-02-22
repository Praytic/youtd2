extends ItemBehavior


var flames_bt: BuffType


func item_init():
	flames_bt = BuffType.create_aura_effect_type("flames_bt", true, self)
	flames_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	flames_bt.set_buff_tooltip(tr("KT5P"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATK_CRIT_CHANCE, 0.035, 0.0008)
	flames_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 300
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = flames_bt
	item.add_aura(aura)
