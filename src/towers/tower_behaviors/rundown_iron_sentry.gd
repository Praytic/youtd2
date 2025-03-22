extends TowerBehavior


var alert_bt: BuffType
var trespasser_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {alert_duration = 5, armor_shred_chance = 0.40, armor_shred_amount = 3, armor_shred_amount_add = 0.10, awareness_duration = 5},
		2: {alert_duration = 10, armor_shred_chance = 0.50, armor_shred_amount = 4, armor_shred_amount_add = 0.15, awareness_duration = 8},
		3: {alert_duration = 15, armor_shred_chance = 0.60, armor_shred_amount = 5, armor_shred_amount_add = 0.20, awareness_duration = 12},
	}

const ARMOR_SHRED_STACKS_MAX: int = 5
const ALERT_MOD_DMG: float = 0.075
const ALERT_MOD_DMG_ADD: float = 0.005
const ALERT_RANGE: int = 500
const TRESSPASSER_RANGE: int = 925


func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, TRESSPASSER_RANGE, TargetType.new(TargetType.CREEPS))


func tower_init():
	alert_bt = BuffType.new("alert_bt", 0, 0, true, self)
	var alert_mod: Modifier = Modifier.new()
	alert_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, ALERT_MOD_DMG, ALERT_MOD_DMG_ADD)
	alert_bt.set_buff_modifier(alert_mod)
	alert_bt.set_buff_icon("res://resources/icons/generic_icons/barbute.tres")
	alert_bt.set_buff_tooltip(tr("RILU"))

	trespasser_bt = BuffType.new("trespasser_bt", -1, 0, false, self)
	var trespasser_mod: Modifier = Modifier.new()
	trespasser_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.01)
	trespasser_bt.set_buff_modifier(trespasser_mod)
	trespasser_bt.set_buff_icon("res://resources/icons/generic_icons/semi_closed_eye.tres")
	trespasser_bt.set_buff_tooltip(tr("G6KV"))


func on_unit_in_range(event: Event):
	var creep: Unit = event.get_target()
	var creep_size: CreepSize.enm = creep.get_size_including_challenge_sizes()
	var level: int = tower.get_level()
	var buff: Buff = creep.get_buff_of_type(trespasser_bt)

	var buff_level: int = int((_stats.armor_shred_amount + _stats.armor_shred_amount_add * level) * 100)
	if buff != null:
		buff_level = min(buff_level + buff.get_level(), buff_level * ARMOR_SHRED_STACKS_MAX)

#	NOTE: original script relies of sizes mapping to
#	specific int's. Do this mapping here instead.
	var size_multiplier_map: Dictionary = {
		CreepSize.enm.MASS: 1,
		CreepSize.enm.NORMAL: 3,
		CreepSize.enm.AIR: 4,
		CreepSize.enm.CHAMPION: 5,
		CreepSize.enm.CHALLENGE_MASS: 2,
		CreepSize.enm.BOSS: 6,
		CreepSize.enm.CHALLENGE_BOSS: 8,
	}
	var size_multiplier: int = size_multiplier_map[creep_size]

	var mod_damage_value: float = (0.05 + 0.001 * level) * size_multiplier

	var alert_sizes: Array[CreepSize.enm] = [
		CreepSize.enm.AIR,
		CreepSize.enm.CHAMPION,
		CreepSize.enm.BOSS,
		CreepSize.enm.CHALLENGE_BOSS
	]
	var size_is_big_enough_for_alert: bool = alert_sizes.has(creep_size)

	if tower.calc_chance(_stats.armor_shred_chance):
		var trespasser_buff: Buff = trespasser_bt.apply(tower, creep, buff_level)
		trespasser_buff.set_displayed_stacks(trespasser_buff.get_level())

	tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, mod_damage_value)

	if size_is_big_enough_for_alert:
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), ALERT_RANGE)

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			var alert_duration: float = _stats.alert_duration
			alert_bt.apply_custom_timed(tower, next, 0, alert_duration)

	await Utils.create_manual_timer(_stats.awareness_duration, self).timeout

	if Utils.unit_is_valid(tower):
		tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, -mod_damage_value)
