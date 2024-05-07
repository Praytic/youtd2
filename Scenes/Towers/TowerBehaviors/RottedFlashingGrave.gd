extends TowerBehavior

# NOTE: modified this script because the original did a
# bunch of unnecessary things.


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Wrath of the Storm - Aura"
	ability.description_short = "This tower attacks random targets.\n"
	ability.description_full = "The enormous wrath of the dead warrior flows out of this tower undirected. So the tower only hits a random target in range each attack.\n"
	list.append(ability)

	return list


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.10, 0.01)


func on_attack(_event: Event):
	var iterator: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), tower.get_range())
	var random_unit: Unit = iterator.next_random()

	tower.issue_target_order(random_unit)
