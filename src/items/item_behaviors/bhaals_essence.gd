extends ItemBehavior


# NOTE: [ORIGINAL_GAME_BUG] Fixed bug where slow debuff
# wasn't attached to aura. This caused the item to not slow
# the creeps.


var fright_bt: BuffType


func load_modifier(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DEBUFF_DURATION, -0.60, 0.0)


func item_init():
	fright_bt = BuffType.create_aura_effect_type("fright_bt", true, self)
	fright_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	fright_bt.set_buff_tooltip(tr("ND86"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_MOVESPEED, -0.10, -0.0020)
	mod.add_modification(Modification.Type.MOD_ARMOR, -4.00, -0.2)
	fright_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 650
	aura.target_type = TargetType.new(TargetType.CREEPS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = fright_bt
	item.add_aura(aura)
