extends TowerBehavior


var chaos_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 750, TargetType.new(TargetType.CREEPS))


func tower_init():
	chaos_bt = BuffType.new("chaos_bt", 3.0, 0.1, false, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(ModificationType.enm.MOD_ARMOR_PERC, -1.0, 0.50)
	chaos_bt.set_buff_modifier(mod)
	chaos_bt.set_buff_icon("res://resources/icons/generic_icons/mine_explosion.tres")
	chaos_bt.set_buff_tooltip(tr("HEC8"))


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
