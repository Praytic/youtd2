extends Builder

# TODO: implement +3 extra cube recipes
# TODO: only wield items that match tier rarity


func _init():
	GoldControl.modify_income_rate(0.15)
	GoldControl.modify_interest_rate(0.02)


func _get_tower_modifier() -> Modifier:
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_BOUNTY_RECEIVED, 0.20, 0.0)
	mod.add_modification(Modification.Type.MOD_ITEM_QUALITY_ON_KILL, 0.35, 0.02)

	mod.add_modification(Modification.Type.MOD_BUFF_DURATION, -0.35, 0.0)
	mod.add_modification(Modification.Type.MOD_DEBUFF_DURATION, 0.25, 0.0)
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.15, 0.0)

	return mod
