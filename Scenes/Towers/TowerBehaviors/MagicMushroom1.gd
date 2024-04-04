extends TowerBehavior


var trance_bt: BuffType
var fungus_bt: BuffType
var multiboard: MultiboardValues
var growth_count: int = 0
var spell_damage_from_growth: float = 0.0
var fungus_strike_activated: bool = false


func get_ability_description() -> String:
	var text: String = ""

	text += "[color=GOLD]Fungus Strike[/color]\n"
	text += "After casting Mystical Trance the Mushroom's next attack will deal 100% of its damage as spell damage with an additional 20% chance to crit. Additionally makes the target creep receive 10% more damage from spells. This effect is permanent and stacks.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% spell damage\n"
	text += "+0.8% spell crit chance\n"
	text += " \n"

	text += "[color=GOLD]Rapid Growth[/color]\n"
	text += "Every 20 seconds the Mushroom has a 40% chance to grow, permanently gaining 3% bonus spell damage. Maximum of 40 succesful growths.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "-0.4 seconds\n"
	text += "+0.12% bonus spell damage\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Fungus Strike[/color]\n"
	text += "Casting Mystical Trance empowers the Mushroom and makes creeps weaker.\n"
	text += " \n"

	text += "[color=GOLD]Rapid Growth[/color]\n"
	text += "Chance to grow, permanently gaining bonus spell damage.\n"

	return text


func get_autocast_description() -> String:
	var text: String = ""

	text += "Buffs a tower in 500 range, increasing its spell damage and trigger chances by 25%. Lasts 5 seconds.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.2 sec duration\n"
	text += "+1% spell damage\n"
	text += "+1% trigger chances\n"

	return text


func get_autocast_description_short() -> String:
	return "Buffs a tower in range, increasing its spell damage and trigger chances.\n"


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_periodic_event(periodic, 20.0)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_MANA_REGEN, 0.0, 0.16)


func get_ability_ranges() -> Array[RangeData]:
	return [RangeData.new("Mystical Trance", 900, TargetType.new(TargetType.TOWERS))]


func tower_init():
	fungus_bt = BuffType.new("fungus_bt", 3600, 0, false, self)
	fungus_bt.set_buff_icon("fireball.tres")
	fungus_bt.set_buff_tooltip("Fungus Strike\nIncreases spell damage taken.")

	trance_bt = BuffType.new("trance_bt", 5, 0.2, true, self)
	var drol_mushroom_trance_mod: Modifier = Modifier.new()
	drol_mushroom_trance_mod.add_modification(Modification.Type.MOD_SPELL_DAMAGE_DEALT, 0.25, 0.01)
	drol_mushroom_trance_mod.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.25, 0.01)
	trance_bt.set_buff_modifier(drol_mushroom_trance_mod)
	trance_bt.set_buff_icon("beard.tres")
	trance_bt.set_buff_tooltip("Mystical Trance\nIncreases spell damage and trigger chances.")

	multiboard = MultiboardValues.new(2)
	multiboard.set_key(0, "Growths")
	multiboard.set_key(1, "Spell Damage")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Mystical Trance"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "AIreTarget.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_BUFF
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 500
	autocast.auto_range = 500
	autocast.cooldown = 2
	autocast.mana_cost = 50
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = trance_bt
	autocast.target_type = TargetType.new(TargetType.TOWERS)
	autocast.handler = on_autocast
	tower.add_autocast(autocast)


func on_damage(event: Event):
	var target: Unit = event.get_target()

	if !fungus_strike_activated || !event.is_main_target():
		return

	CombatLog.log_ability(tower, target, "Fungus Strike")

	fungus_strike_activated = false

	fungus_bt.apply(tower, target, tower.get_level())
	target.modify_property(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.10)
	var fungus_strike_damage: float = event.damage * (1.0 + 0.01 * tower.get_level())
	tower.do_spell_damage(target, fungus_strike_damage, tower.calc_spell_crit(0.20 + 0.008 * tower.get_level(), 0))
	event.damage = 0


func on_tower_details() -> MultiboardValues:
	var growth_count_string: String = str(growth_count)
	var spell_damage_string: String = Utils.format_percent(spell_damage_from_growth, 0)

	multiboard.set_value(0, growth_count_string)
	multiboard.set_value(1, spell_damage_string)

	return multiboard


func periodic(event: Event):
	var lvl: int = tower.get_level()

	if !tower.calc_chance(0.4):
		CombatLog.log_ability(tower, null, "Growth Fail")

		return

	CombatLog.log_ability(tower, null, "Growth")

	var spell_damage_bonus: float = 0.03 + 0.0012 * lvl

	tower.modify_property(Modification.Type.MOD_SPELL_DAMAGE_DEALT, spell_damage_bonus)
	spell_damage_from_growth += spell_damage_bonus

	var target_effect: int = Effect.create_scaled("TargetArtLumber.mdl", tower.get_visual_x(), tower.get_visual_y(), 30, 0, 5)
	Effect.set_lifetime(target_effect, 1.0)

	growth_count += 1

#	TODO: implement Unit.set_unit_scale()
#	var scale_from_growth: float = 1.25 + 0.015 * growth_count
#	SetUnitScale(tower, scale_from_growth)

	var periodic_time: float = 20 - 0.4 * lvl
	event.enable_advanced(periodic_time, false)


func on_autocast(event: Event):
	var target: Unit = event.get_target()
	fungus_strike_activated = true

	trance_bt.apply(tower, target, tower.get_level())
