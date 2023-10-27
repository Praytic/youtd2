extends Tower

# NOTE: modified this script because the original did a
# bunch of unnecessary things.


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Wrath of the Storm - Aura[/color]\n"
	text += "The enormous wrath of the dead warrior flows out of this tower undirected. So the tower only hits a random target in range each attack.\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Wrath of the Storm[/color]\n"
	text += "This tower attacks random targets.\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.10, 0.01)


func on_attack(event: Event):
	var b: Buff = event.get_buff()

	var tower: Tower = b.get_caster()
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())
	var random_unit: Unit = iterator.next_random()

	issue_target_order("attack", random_unit)
