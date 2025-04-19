extends TowerBehavior


var armor_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {armor_decrease = 2},
		2: {armor_decrease = 3},
		3: {armor_decrease = 5},
		4: {armor_decrease = 7},
		5: {armor_decrease = 10},
	}


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func tower_init():
	var armor: Modifier = Modifier.new()
	armor.add_modification(ModificationType.enm.MOD_ARMOR, 0, -1)
	armor_bt = BuffType.new("armor_bt", 0, 0, false, self)
	armor_bt.set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	armor_bt.set_buff_modifier(armor)

	armor_bt.set_buff_tooltip(tr("Y0QD"))


func on_damage(event: Event):
	var lvl: int = tower.get_level()
	var creep: Unit = event.get_target()
	var size_factor: float = 1.0

	if creep.get_size() == CreepSize.enm.BOSS:
		size_factor = 2.0

	if tower.calc_chance((0.05 + lvl * 0.006) * size_factor):
		CombatLog.log_ability(tower, creep, "Afterglow")
		
		armor_bt.apply_custom_timed(tower, creep, _stats.armor_decrease, 5 + lvl * 0.25)
