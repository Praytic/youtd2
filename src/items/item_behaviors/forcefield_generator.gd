extends ItemBehavior


var forcefield_bt: BuffType


func item_init():
	forcefield_bt = BuffType.create_aura_effect_type("forcefield_bt", true, self)
	forcefield_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	forcefield_bt.set_buff_tooltip(tr("X440"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.15, -0.01)
	forcefield_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = forcefield_bt
	item.add_aura(aura)
