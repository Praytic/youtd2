extends Tower


var dave_knight_will_positive_bt: BuffType
var dave_knight_will_negative_bt: BuffType
var dave_knight_withering_bt: BuffType


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Insatiable Hunger[/color]\n"
	text += "On each attack, the death knight deals 0.25% bonus damage for each mana point he's currently missing and replenishes 1% of his maximum mana. He replenishes 5% of his maximum mana for each unit he kills.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.01% damage per mana point\n"
	text += " \n"

	text += "[color=GOLD]Withering Presence[/color]\n"
	text += "Whenever a unit comes in 900 range of the death knight, it has a 15% chance to have its health regeneration reduced by 50% and to lose 5% of its current health every second for 4 seconds. Units affected by this spell grant 50% less experience and bounty on death.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.4% chance\n"
	text += "+1% health regen reduction\n"
	text += "-1% experience and bounty reduction\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Insatiable Hunger[/color]\n"
	text += "Deals bonus damage based on missing mana and replenishes mana when attacking.\n"
	text += " \n"

	text += "[color=GOLD]Withering Presence[/color]\n"
	text += "Chance to steal health of nearby creeps.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "The death knight decreases the base attack damage of all towers in 200 range by 10% and loses 50% of his remaining mana to increase his base damage by 15% for each tower affected for 5 seconds. Only towers that cost at least 1300 gold are affected by this spell.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2% damage absorbed\n"

	return text


func get_autocast_description_short() -> String:
	return "The death knight empowers himself by draining the power of nearby towers.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_kill(on_kill)
	triggers.add_event_on_unit_comes_in_range(on_unit_in_range, 900, TargetType.new(TargetType.CREEPS))


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA, 0.0, 2.0)


func tower_init():
	dave_knight_will_positive_bt = BuffType.new("dave_knight_will_positive_bt", 5, 0, true, self)
	var dave_knight_will_positive_bt_mod: Modifier = Modifier.new()
	dave_knight_will_positive_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, 0.002)
	dave_knight_will_positive_bt.set_buff_modifier(dave_knight_will_positive_bt_mod)
	dave_knight_will_positive_bt.set_buff_icon("@@0@@")
	dave_knight_will_positive_bt.set_buff_tooltip("Will of the Undying\nThis tower is empowered by Will of the Undying; it will deal more damage.")

	dave_knight_will_negative_bt = BuffType.new("dave_knight_will_negative_bt", 5, 0, false, self)
	var dave_knight_will_negative_bt_mod: Modifier = Modifier.new()
	dave_knight_will_negative_bt_mod.add_modification(Modification.Type.MOD_DAMAGE_BASE_PERC, 0.0, -0.002)
	dave_knight_will_negative_bt.set_buff_modifier(dave_knight_will_negative_bt_mod)
	dave_knight_will_negative_bt.set_buff_icon("@@1@@")
	dave_knight_will_negative_bt.set_buff_tooltip("Will of the Undying\nThis tower is drained by Will of the Undying; it will deal less damage.")

	dave_knight_withering_bt = BuffType.new("dave_knight_withering_bt", 4, 0, false, self)
	var dave_knight_withering_bt_mod: Modifier = Modifier.new()
	dave_knight_withering_bt_mod.add_modification(Modification.Type.MOD_HP_REGEN_PERC, -0.5, -0.1)
	dave_knight_withering_bt_mod.add_modification(Modification.Type.MOD_EXP_GRANTED, -0.5, 0.01)
	dave_knight_withering_bt_mod.add_modification(Modification.Type.MOD_BOUNTY_GRANTED, -0.5, 0.01)
	dave_knight_withering_bt.set_buff_modifier(dave_knight_withering_bt_mod)
	dave_knight_withering_bt.set_buff_icon("@@2@@")
	dave_knight_withering_bt.set_buff_tooltip("Withering Presence\nThis tower is affected by Withering Presence; it has reduced health regeneration and will periodically lose health.")
	dave_knight_withering_bt.add_periodic_event(dave_knight_withering_bt_periodic, 1.0)

	var autocast: Autocast = Autocast.make()
	autocast.title = "Will of the Undying"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "HowlCaster.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.num_buffs_before_idle = 0
	autocast.cast_range = 900
	autocast.auto_range = 900
	autocast.cooldown = 10
	autocast.mana_cost = 50
	autocast.target_self = false
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_damage(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var mana: float = tower.get_mana()
	var max_mana: float = tower.get_overall_mana()
	var mana_gain: float = max_mana * 0.01
	var damage_bonus_from_mana: float = event.damage * (max_mana - mana) * (0.025 + 0.001 * level)

	tower.add_mana(mana_gain)
	event.damage += damage_bonus_from_mana


func on_kill(_event: Event):
	var tower: Tower = self
	var max_mana: float = tower.get_overall_mana()
	var mana_gain: float = max_mana * 0.05

	tower.add_mana(mana_gain)


func on_unit_in_range(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var level: int = tower.get_level()
	var withering_presence_chance: float = 0.15 + 0.004 * level

	if !tower.calc_chance(withering_presence_chance):
		return

	CombatLog.log_ability(tower, target, "Withering Presence")

	dave_knight_withering_bt.apply(tower, target, level)


func on_autocast(_event: Event):
	var tower: Tower = self
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

		dave_knight_will_negative_bt.apply(tower, next, 50 + level)

	if tower_count > 0:
		dave_knight_will_positive_bt.apply(tower, tower, (75 + level) * tower_count)

	if tower_count == 0:
		CombatLog.log_ability(tower, null, "Will of the Undying failed because nearby towers are cheap")


func dave_knight_withering_bt_periodic(event: Event):
	var buff: Buff = event.get_buff()
	var buffed_unit: Unit = buff.get_buffed_unit()
	var hp: float = buffed_unit.get_health()
	var hp_loss: float = hp * 0.05

	buffed_unit.set_health(hp - hp_loss)
