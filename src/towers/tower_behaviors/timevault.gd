extends TowerBehavior


var aura_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	aura_bt = BuffType.create_aura_effect_type("aura_bt", true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_TRIGGER_CHANCES, 0.30, 0.006)
	aura_bt.set_buff_modifier(mod)
	aura_bt.set_buff_icon("res://resources/icons/generic_icons/electric.tres")
	aura_bt.set_buff_tooltip(tr("CC46"))


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
