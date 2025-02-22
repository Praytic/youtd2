extends ItemBehavior

# NOTE: [ORIGINAL_GAME_DEVIATION] Renamed
# "Warsong Double Bass"=>"War Drum"


var drum_bt: BuffType


func item_init():
	drum_bt = BuffType.create_aura_effect_type("drum_bt", true, self)
	drum_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	drum_bt.set_buff_tooltip(tr("LBDS"))
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 0.075, 0.001)
	drum_bt.set_buff_modifier(mod)

	var aura: AuraType = AuraType.new()
	aura.aura_range = 200
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = true
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = drum_bt
	item.add_aura(aura)
