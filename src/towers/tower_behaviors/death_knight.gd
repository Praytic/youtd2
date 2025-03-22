extends TowerBehavior


var will_positive_bt: BuffType
var will_negative_bt: BuffType
var withering_bt: BuffType


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 900, TargetType.new(TargetType.CREEPS))


func tower_init():
	will_positive_bt = BuffType.new("will_positive_bt", 5, 0, true, self)
	var will_positive_bt_mod: Modifier = Modifier.new()
	will_positive_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.002)
	will_positive_bt.set_buff_modifier(will_positive_bt_mod)
	will_positive_bt.set_buff_icon("res://resources/icons/generic_icons/alien_skull.tres")
	will_positive_bt.set_buff_tooltip(tr("Q60A"))

	will_negative_bt = BuffType.new("will_negative_bt", 5, 0, false, self)
	var will_negative_bt_mod: Modifier = Modifier.new()
	will_negative_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, -0.002)
	will_negative_bt.set_buff_modifier(will_negative_bt_mod)
	will_negative_bt.set_buff_icon("res://resources/icons/generic_icons/pisces.tres")
	will_negative_bt.set_buff_tooltip(tr("BK97"))

	withering_bt = BuffType.new("withering_bt", 4, 0, false, self)
	var withering_bt_mod: Modifier = Modifier.new()
	withering_bt_mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.5, -0.1)
	withering_bt_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, -0.5, 0.01)
	withering_bt_mod.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -0.5, 0.01)
	withering_bt.set_buff_modifier(withering_bt_mod)
	withering_bt.set_buff_icon("res://resources/icons/generic_icons/ghost.tres")
	withering_bt.set_buff_tooltip(tr("JRGL"))
	withering_bt.add_periodic_event(withering_bt_periodic, 1.0)


func on_damage(event: Event):
	var level: int = tower.get_level()
	var mana: float = tower.get_mana()
	var max_mana: float = tower.get_overall_mana()
	var mana_gain: float = max_mana * 0.01
	var damage_bonus_from_mana: float = event.damage * (max_mana - mana) * (0.025 + 0.001 * level)

	tower.add_mana(mana_gain)
	event.damage += damage_bonus_from_mana


func on_kill(_event: Event):
	var max_mana: float = tower.get_overall_mana()
	var mana_gain: float = max_mana * 0.05

	tower.add_mana(mana_gain)


func on_unit_in_range(event: Event):
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var withering_presence_chance: float = 0.15 + 0.004 * level

	if !tower.calc_chance(withering_presence_chance):
		return

	CombatLog.log_ability(tower, target, "Withering Presence")

	withering_bt.apply(tower, target, level)


func on_autocast(_event: Event):
	var level: int = tower.get_level()
	var it: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.TOWERS), 200)
	var mana: float = tower.get_mana()
	var tower_count: int = 0

	tower.set_mana(mana / 2)

	while true:
		var next: Unit = it.next()

		if next == null:
			break

		if next == tower || next.get_gold_cost() < 1300:
			continue

		tower_count += 1

		will_negative_bt.apply(tower, next, 50 + level)

	if tower_count > 0:
		will_positive_bt.apply(tower, tower, (75 + level) * tower_count)

	if tower_count == 0:
		CombatLog.log_ability(tower, null, "Will of the Undying failed because nearby towers are cheap")


func withering_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var hp: float = buffed_unit.get_health()
	var hp_loss: float = hp * 0.05

	buffed_unit.set_health(hp - hp_loss)
