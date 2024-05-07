extends TowerBehavior


var chaos_bt: BuffType


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var ability: AbilityInfo = AbilityInfo.new()
	ability.name = "Chaos"
	ability.description_short = "All creeps that come in range have a chance to lose their armor.\n"
	ability.description_full = "All creeps that come in 750 range around this tower have a 45% chance to lose 100% of their armor for 3 seconds. The armor reduction is halved for Bosses and Challenges.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.1 seconds\n" \
	+ "+0.4% chance\n"
	list.append(ability)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 750, TargetType.new(TargetType.CREEPS))


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_HUMANOID, 0.25, 0.01)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Monolith of Chaos", 750, TargetType.new(TargetType.CREEPS))]


func tower_init():
	chaos_bt = BuffType.new("chaos_bt", 3.0, 0.1, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -1.0, 0.50)
	chaos_bt.set_buff_modifier(mod)
	chaos_bt.set_buff_icon("res://Resources/Textures/GenericIcons/mine_explosion.tres")
	chaos_bt.set_buff_tooltip("Chaos\nRemoves all armor.")


func on_unit_in_range(event: Event, ):
	var creep: Unit = event.get_target()
	var level: int = tower.get_level()
	var chaos_chance: float = 0.45 + 0.004 * level
	var buff_duration: float = 3.0 + 0.1 * level

	if !tower.calc_chance(chaos_chance):
		return

	var creep_size: CreepSize.enm = creep.get_size()

	var buff_level: int
	if creep_size < CreepSize.enm.BOSS:
		buff_level = 0
	else:
		buff_level = 1

	chaos_bt.apply_custom_timed(tower, creep, buff_level, buff_duration)
