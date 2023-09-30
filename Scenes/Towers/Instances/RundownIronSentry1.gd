extends Tower


var glow_alert_bt: BuffType
var glow_trespasser_bt: BuffType


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


func get_extra_tooltip_text() -> String:
	var alert_duration: String = Utils.format_float(_stats.alert_duration, 2)
	var alert_range: String = Utils.format_float(ALERT_RANGE, 2)
	var alert_mod_dmg: String = Utils.format_percent(ALERT_MOD_DMG, 2)
	var alert_mod_dmg_add: String = Utils.format_percent(ALERT_MOD_DMG_ADD, 2)
	var armor_shred_chance: String = Utils.format_percent(_stats.armor_shred_chance, 2)
	var armor_shred_amount: String = Utils.format_float(_stats.armor_shred_amount, 2)
	var armor_shred_amount_add: String = Utils.format_float(_stats.armor_shred_amount_add, 2)
	var awareness_duration: String = Utils.format_float(_stats.awareness_duration, 2)
	var armor_shred_stacks_max: String = Utils.format_float(ARMOR_SHRED_STACKS_MAX, 2)

	var text: String = ""

	text += "[color=GOLD]Alert[/color]\n"
	text += "Towers in %s range get alerted whenever a creep of size air, champion or boss enters the sentry's attack range. They have their base damage increased by %s for %s seconds. Does not stack.\n" % [alert_range, alert_mod_dmg, alert_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s base damage bonus\n" % alert_mod_dmg_add
	text += " \n"
	text += "[color=GOLD]Trespasser Awareness[/color]\n"
	text += "This tower strengthens its defenses when uninvited units enter its territory. It gains bonus 5%%-40%% base percent damage with each creep entering its attack range, based on the creep's size. Bonus damage lasts %s seconds and new stacks of damage do not refresh duration of old ones. There is also a %s chance that the trespassing creep will permanently have its armor reduced by %s, which stacks up to %s times.\n" % [awareness_duration, armor_shred_chance, armor_shred_amount, armor_shred_stacks_max]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s armor reduction\n" % [armor_shred_amount_add]
	text += "+0.1%-0.8% bonus base percent damage\n"

	return text



func load_triggers(triggers: BuffType):
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 925, TargetType.new(TargetType.CREEPS))



func tower_init():
	glow_alert_bt = BuffType.new("glow_alert_bt", 0, 0, true, self)
	var alert_mod: Modifier = Modifier.new()
	alert_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, ALERT_MOD_DMG, ALERT_MOD_DMG_ADD)
	glow_alert_bt.set_buff_modifier(alert_mod)
	glow_alert_bt.set_buff_icon("@@0@@")
	glow_alert_bt.set_buff_tooltip("Alert\nThis tower has been alerted; it has increased base damage.")

	glow_trespasser_bt = BuffType.new("glow_trespasser_bt", -1, 0, false, self)
	var trespasser_mod: Modifier = Modifier.new()
	trespasser_mod.add_modification(Modification.Type.MOD_ARMOR, 0.0, -0.01)
	glow_trespasser_bt.set_buff_modifier(trespasser_mod)
	glow_trespasser_bt.set_buff_icon("@@1@@")
	glow_trespasser_bt.set_buff_tooltip("Trespasser\nThis unit is a tresspasser; it has reduced armor.")


func on_unit_in_range(event: Event):
	var tower: Tower = self
	var creep: Unit = event.get_target()
	var creep_size: CreepSize.enm = creep.get_size()
	var level: int = tower.get_level()
	var buff: Buff = creep.get_buff_of_type(glow_trespasser_bt)

	var buff_level: int = int((_stats.armor_shred_amount + _stats.armor_shred_amount_add * level) * 100)
	if buff != null:
		buff_level = min(buff_level + buff.get_level(), buff_level * ARMOR_SHRED_STACKS_MAX)

#	NOTE: original script relies of sizes mapping to
#	specific int's. Do this mapping here instead.
	var size_multiplier_map: Dictionary = {
		CreepSize.enm.MASS: 1,
		CreepSize.enm.NORMAL: 2,
		CreepSize.enm.AIR: 3,
		CreepSize.enm.CHAMPION: 4,
		CreepSize.enm.CHALLENGE_MASS: 8,
		CreepSize.enm.BOSS: 5,
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
		glow_trespasser_bt.apply(tower, creep, buff_level)

	tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, mod_damage_value)

	if size_is_big_enough_for_alert:
		var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), ALERT_RANGE)

		while true:
			var next: Unit = it.next()

			if next == null:
				break

			var alert_duration: float = _stats.alert_duration
			glow_alert_bt.apply_custom_timed(tower, next, 0, alert_duration)

	await get_tree().create_timer(_stats.awareness_duration).timeout

	if Utils.unit_is_valid(tower):
		tower.modify_property(Modification.Type.MOD_DAMAGE_BASE_PERC, -mod_damage_value)
