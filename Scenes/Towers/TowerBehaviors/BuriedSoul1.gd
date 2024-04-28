extends TowerBehavior


var cripple_bt: BuffType
var banish_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {banish_lvl = 40, banish_lvl_add = 0.32, banish_duration = 2.5, cripple_duration = 2.5, damage = 80, damage_add = 4},
		2: {banish_lvl = 60, banish_lvl_add = 0.48, banish_duration = 3.0, cripple_duration = 3.0, damage = 310, damage_add = 15.5},
		3: {banish_lvl = 80, banish_lvl_add = 0.64, banish_duration = 3.5, cripple_duration = 3.5, damage = 1240, damage_add = 62},
		4: {banish_lvl = 100, banish_lvl_add = 0.80, banish_duration = 4.0, cripple_duration = 4.0, damage = 2450, damage_add = 122.5},
	}


func get_ability_description() -> String:
	var banish_lvl: String = Utils.format_percent(_stats.banish_lvl * 0.01, 2)
	var banish_duration: String = Utils.format_float(_stats.banish_duration, 2)
	var banish_lvl_add: String = Utils.format_percent(_stats.banish_lvl_add * 0.01, 2)
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Soul Scattering[/color]\n"
	text += "10%% chance on attack to reduce its own attackspeed by 60%% and make the target receive %s more spell damage. Both effects last %s seconds.\n" % [banish_lvl, banish_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+1% attackspeed\n"
	text += "+%s spell damage received\n" % banish_lvl_add
	text += " \n"
	text += "[color=GOLD]Shadowstrike[/color]\n"
	text += "This tower has a 25%% chance on attack to deal %s spell damage.\n" % damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage\n" % damage_add
	text += "+0.5% chance"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Soul Scattering[/color]\n"
	text += "Chance on attack reduce its own attack speed and make the target more vulnerable to spells.\n"
	text += " \n"
	text += "[color=GOLD]Shadowstrike[/color]\n"
	text += "Chance on attack to deal additional spell damage.\n"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_attack(on_attack)


func tower_init():
	var banish: Modifier = Modifier.new()
	var cripple: Modifier = Modifier.new()

	cripple_bt = BuffType.new("cripple_bt", 0.0, 0, false, self)
	banish_bt = BuffType.new("banish_bt", 0.0, 0, false, self)
	cripple_bt.set_buff_icon("res://Resources/Textures/GenericIcons/triple_scratches.tres")
	cripple_bt.set_special_effect("Abilities\\Spells\\Undead\\Cripple\\CrippleTarget.mdl", 150, 5.0)
	banish_bt.set_buff_icon("res://Resources/Textures/GenericIcons/alien_skull.tres")
	banish.add_modification(Modification.Type.MOD_SPELL_DAMAGE_RECEIVED, 0.0, 0.0001)
	cripple.add_modification(Modification.Type.MOD_ATTACKSPEED, -0.6, 0.01)
	cripple_bt.set_buff_modifier(cripple)
	banish_bt.set_buff_modifier(banish)

	cripple_bt.set_buff_tooltip("Cripple\nReduces attack speed.")
	banish_bt.set_buff_tooltip("Banish\nIncreases spell damage taken.")


func on_attack(event: Event):
	var lvl: int = tower.get_level()
	var creep: Creep = event.get_target()

	if tower.calc_chance(0.1):
		CombatLog.log_ability(tower, creep, "Soul Scattering")

		banish_bt.apply_custom_timed(tower, creep, int((_stats.banish_lvl + _stats.banish_lvl_add * lvl) * 100), _stats.banish_duration)
		cripple_bt.apply_custom_timed(tower, tower, lvl, _stats.cripple_duration)

	if tower.calc_chance(0.25 + 0.005 * lvl):
		CombatLog.log_ability(tower, creep, "Shadowstrike")
		
		tower.do_spell_damage(creep, _stats.damage + tower.get_level() * _stats.damage_add, tower.calc_spell_crit_no_bonus())
		SFX.sfx_on_unit("Abilities\\Spells\\Undead\\DeathPact\\DeathPactTarget.mdl", creep, Unit.BodyPart.ORIGIN)
