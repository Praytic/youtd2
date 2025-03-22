extends TowerBehavior


var rage_bt: BuffType
var feral_bt: BuffType
var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {feral_dmg_gain = 0.002, feral_dmg_max = 2.00, bloodthirst_attack_speed = 1.00, bloodthirst_duration = 3, rage_buff_level_base = 0},
		2: {feral_dmg_gain = 0.003, feral_dmg_max = 2.25, bloodthirst_attack_speed = 1.25, bloodthirst_duration = 4, rage_buff_level_base = 25},
		3: {feral_dmg_gain = 0.004, feral_dmg_max = 2.50, bloodthirst_attack_speed = 1.50, bloodthirst_duration = 5, rage_buff_level_base = 50},
	}


const BLOODTHIRST_ATTACKSPEED_ADD: float = 0.01
const BLOODTHIRST_DURATION_ADD: float = 0.05


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)


func tower_init():
	rage_bt = BuffType.new("rage_bt", 0, 0, true, self)
	var mod: Modifier = Modifier.new()
	mod.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.0, BLOODTHIRST_ATTACKSPEED_ADD)
	rage_bt.set_buff_modifier(mod)
	rage_bt.set_buff_icon("res://resources/icons/generic_icons/mighty_force.tres")
	rage_bt.set_buff_tooltip(tr("BLU0"))

	feral_bt = BuffType.new("feral_bt", -1, 0, true, self)
	feral_bt.set_buff_icon("res://resources/icons/generic_icons/orc_head.tres")
	feral_bt.set_buff_tooltip(tr("XZ11"))

	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Damage Bonus")


func on_damage(event: Event):
	if event.is_attack_damage_critical() && tower.user_real <= _stats.feral_dmg_max:
		tower.user_real += _stats.feral_dmg_gain
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, _stats.feral_dmg_gain)

		var feral_buff: Buff = tower.get_buff_of_type(feral_bt)
		var feral_stack_count: int = floori(tower.user_real * 100)
		feral_buff.set_displayed_stacks(feral_stack_count)


func on_kill(_event: Event):
	var lvl: int = tower.get_level()
	var buff_level: int = lvl + _stats.rage_buff_level_base
	var buff_duration: float = _stats.bloodthirst_duration + BLOODTHIRST_DURATION_ADD * lvl

	if tower.get_buff_of_type(rage_bt) == null:
		CombatLog.log_ability(tower, null, "Bloodthirst")

		rage_bt.apply_custom_timed(tower, tower, buff_level, buff_duration)


func on_create(preceding: Tower):
	if preceding != null && preceding.get_family() == tower.get_family():
		var damage_bonus: float = preceding.user_real
		tower.user_real = damage_bonus
		tower.modify_property(Modification.Type.MOD_DAMAGE_ADD_PERC, damage_bonus)
	else:
		tower.user_real = 0.0

	var feral_buff: Buff = feral_bt.apply_to_unit_permanent(tower, tower, 0)
	var feral_stack_count: int = floori(tower.user_real * 100)
	feral_buff.set_displayed_stacks(feral_stack_count)


func on_tower_details() -> MultiboardValues:
	var damage_bonus: String = Utils.format_percent(tower.user_real, 1)

	multiboard.set_value(0, damage_bonus)

	return multiboard
