extends Builder


func _init():
	KnowledgeTomesManager.add_knowledge_tomes(65)
	FoodManager.modify_food_cap(20)


func _get_tower_buff() -> BuffType:
	var bt: BuffType = BuffType.new("", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_DMG_TO_ORC, 0.25, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.20, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_NATURE, -0.20, 0.0)
	mod.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, -0.05, 0.0)
	bt.set_buff_modifier(mod)

	return bt


func _on_wave_level_changed():
	KnowledgeTomesManager.add_knowledge_tomes(2)

