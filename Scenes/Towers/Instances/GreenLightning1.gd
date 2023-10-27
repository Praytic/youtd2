extends Tower


var drol_surge: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {drol_surge_level_bonus = 0, spell_crit = 0.050, spell_crit_add = 0.0010, damage_from_mana_multiplier = 15},
		2: {drol_surge_level_bonus = 25, spell_crit = 0.075, spell_crit_add = 0.0015, damage_from_mana_multiplier = 25},
		3: {drol_surge_level_bonus = 50, spell_crit = 0.100, spell_crit_add = 0.0020, damage_from_mana_multiplier = 35},
		4: {drol_surge_level_bonus = 75, spell_crit = 0.125, spell_crit_add = 0.0025, damage_from_mana_multiplier = 45},
	}


func get_ability_description() -> String:
	var spell_crit: String = Utils.format_percent(_stats.spell_crit, 2)
	var spell_crit_add: String = Utils.format_percent(_stats.spell_crit_add, 2)
	var damage_from_mana_multiplier: String = Utils.format_float(_stats.damage_from_mana_multiplier, 2)

	var text: String = ""

	text += "[color=GOLD]Mana Feed[/color]\n"
	text += "Attacks restore 4 mana to the tower and increase spell crit chance by %s.\n" % spell_crit
	text += "[color=GOLD]Hint:[/color] Mana regeneration increases mana gained.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell crit chance\n" % spell_crit_add
	text += " \n"
	text += "[color=GOLD]Lightning Burst[/color]\n"
	text += "Grants a 12.5%% chance to deal %s times current mana as spell damage on attack.\n" % damage_from_mana_multiplier
	text += " \n"
	text += "Resets the bonus spell crit of 'Mana Feed'.\n"
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.5% chance\n"

	return text


func get_ability_description_short() -> String:
	var text: String = ""

	text += "[color=GOLD]Mana Feed[/color]\n"
	text += "Attacks restore mana to the tower and increase spell crit chance.\n"
	text += " \n"
	text += "[color=GOLD]Lightning Burst[/color]\n"
	text += "Grants a chance to deal extra spell damage on each attack, resets spell crit bonus of Mana Feed.\n"
	text += " \n"

	return text


func get_autocast_description() -> String:
	var attack_speed: String = Utils.format_percent(1.0 + 0.02 * _stats.drol_surge_level_bonus, 2)

	var text: String = ""

	text += "Increases the attackspeed of this tower by %s for the next 5 attacks. The surge fades after 8 seconds.\n" % attack_speed
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+2% attackspeed\n"
	text += "+1 attack per 5 levels\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Increases the attackspeed of this tower for next few attacks.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)
	triggers.add_event_on_attack(on_attack)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_DMG_TO_MAGIC, 0.20, 0.0)


func on_autocast(_event: Event):
	var tower: Tower = self
	tower.user_int = 5 + tower.get_level() / 5
	drol_surge.apply(tower, tower, tower.get_level() + _stats.drol_surge_level_bonus)


func surge(event: Event):
	var b: Buff = event.get_buff()
	var caster: Unit = b.get_caster()

	if caster.user_int < 1:
		b.remove_buff()
	else:
		caster.user_int = caster.user_int - 1


func tower_init():
	var m: Modifier = Modifier.new()
	drol_surge = BuffType.new("drol_surge", 8, 0, true, self)
	m.add_modification(Modification.Type.MOD_ATTACKSPEED, 1.0, 0.02)
	drol_surge.set_buff_modifier(m)
	drol_surge.set_buff_icon("@@1@@")
	drol_surge.add_event_on_attack(surge)
	drol_surge.set_buff_tooltip("Mana Feed\nThis tower is affected by Mana Feed; it's spell crit chance is increased.")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Lightning Surge"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.cast_range = 1200
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 6
	autocast.is_extended = false
	autocast.mana_cost = 60
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 1200
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_attack(_event: Event):
	var tower: Tower = self
	var mana: float = tower.get_mana()

	tower.set_mana(mana + 4 * tower.get_base_mana_regen_bonus_percent())

	tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, _stats.spell_crit + (tower.get_level() * _stats.spell_crit_add))
	tower.user_real = tower.user_real + _stats.spell_crit + tower.get_level() * _stats.spell_crit_add


func on_damage(event: Event):
	var tower: Tower = self

	if !tower.calc_chance(0.125 + 0.005 * tower.get_level()):
		return

	var creep: Creep = event.get_target()

	if !creep.is_immune():
		var target_effect: int = Effect.create_scaled("ManaFlareBoltImpact.mdl", creep.get_visual_x(), creep.get_visual_y(), 0, 0, 1.8)
		Effect.set_lifetime(target_effect, 1.0)
		tower.do_spell_damage(creep, tower.get_mana() * _stats.damage_from_mana_multiplier, tower.calc_spell_crit_no_bonus())
		tower.modify_property(Modification.Type.MOD_SPELL_CRIT_CHANCE, - tower.user_real)
		tower.user_real = 0.0


func on_create(_preceding_tower: Tower):
	var tower: Tower = self
	tower.user_real = 0.0
	tower.user_int = 0
