extends ItemBehavior


func get_ability_description() -> String:
	var lua_string: String = ArmorType.convert_to_colored_string(ArmorType.enm.LUA)

	var text: String = ""

	text += "[color=GOLD]Shrapnel Munition[/color]\n"
	text += "Increases attack damage against creeps with %s armor by 25%%." % lua_string

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var T: Creep = event.get_target()

	if T.get_armor_type() == ArmorType.enm.LUA:
		event.damage = event.damage * 1.25
		Effect.create_simple_at_unit("res://src/effects/frag_boom_spawn.tscn", T)
