extends TowerBehavior


var aura_bt: BuffType

const AURA_RANGE: int = 600


func get_ability_info_list() -> Array[AbilityInfo]:
	var list: Array[AbilityInfo] = []
	
	var time_travel: AbilityInfo = AbilityInfo.new()
	time_travel.name = "Time Travel"
	time_travel.icon = "res://resources/icons/mechanical/compass.tres"
	time_travel.description_short = "Transports hit creeps back in time after a delay. Has a lower chance for bosses.\n"
	time_travel.description_full = "Transports hit creeps 3 seconds back in time after a 3 second delay. Has a 20% chance to transport bosses, other creeps will be always teleported.\n" \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.5% chance for bosses\n"
	list.append(time_travel)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.30, 0.006)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	aura_bt.set_buff_tooltip("Timesurge\nIncreases trigger chances.")


func get_aura_types() -> Array[AuraType]:
	var aura: AuraType = AuraType.new()

	aura.name = "Timesurge"
	aura.icon = "res://resources/icons/mechanical/lamp.tres"
	aura.description_short = "Increases triggerchance of nearby towers.\n"
	aura.description_full = "Increases triggerchance of towers in %d range by 30%%.\n" % AURA_RANGE \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+0.6% chance\n"

	aura.aura_range = AURA_RANGE
	aura.target_type = TargetType.new(TargetType.TOWERS)
	aura.target_self = false
	aura.level = 0
	aura.level_add = 1
	aura.aura_effect = aura_bt
	return [aura]


func on_damage(event: Event):
	var creep: Creep = event.get_target()
	var target_is_boss: bool = creep.get_size() >= CreepSize.enm.BOSS
	var chance_for_boss: float = 0.20 + 0.005 * tower.get_level()

	if target_is_boss && !tower.calc_chance(chance_for_boss):
		return

	var old_position: Vector2 = creep.get_position_wc3_2d()
	var old_path_index: int = creep._current_path_index
	var effect: int = Effect.create_simple_at_unit_attached("res://src/effects/mass_teleport_caster.tscn", creep, Unit.BodyPart.ORIGIN)
	Effect.set_auto_destroy_enabled(effect, false)

	await Utils.create_manual_timer(3.0, self).timeout

	Effect.destroy_effect(effect)

#	NOTE: need to also restore old path index because
#	otherwise the creep would be teleported to old position
#	but will go in a straight line towards some further path
#	point.
	if Utils.unit_is_valid(creep):
		creep.set_position_wc3_2d(old_position)
		creep._current_path_index = old_path_index
		Effect.create_simple_at_unit("res://src/effects/silence_area.tscn", creep)
