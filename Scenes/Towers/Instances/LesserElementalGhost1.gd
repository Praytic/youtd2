extends Tower


var tomy_ElementalWrath: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {self_trigger_chances = 0.005, trigger_chance_add = 5, elemental_wrath_chance = 0.150},
		2: {self_trigger_chances = 0.006, trigger_chance_add = 6, elemental_wrath_chance = 0.175},
		3: {self_trigger_chances = 0.007, trigger_chance_add = 7, elemental_wrath_chance = 0.200},
		4: {self_trigger_chances = 0.008, trigger_chance_add = 8, elemental_wrath_chance = 0.225},
		5: {self_trigger_chances = 0.009, trigger_chance_add = 9, elemental_wrath_chance = 0.250},
	}


func get_extra_tooltip_text() -> String:
	var trigger_chance_add: String = Utils.format_percent(_stats.trigger_chance_add / 100, 2)
	var elemental_wrath_chance: String = Utils.format_percent(_stats.elemental_wrath_chance, 2)

	var text: String = ""

	text += "[color=GOLD]Elemental Wrath[/color]\n"
	text += "The Elemental Ghost has a %s chance to unleash it's wrath on attack, increasing its trigger chance by 15%% for 5 seconds. Cannot retrigger during Elemental Wrath.\n" % elemental_wrath_chance
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.1 seconds duration\n"
	text += "%s trigger chance increase\n" % trigger_chance_add
	text += " \n"
	text += "[color=GOLD]Mimic[/color]\n"
	text += "The Ghost's attacks are varied, and its damage type will either be good or bad against its target. Trigger chance adjusts the good/bad attacks to be better.\n"

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.0, _stats.self_trigger_chances)


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.0, 0.001)
	tomy_ElementalWrath = BuffType.new("tomy_ElementalWrath", 5, 0, true, self)
	tomy_ElementalWrath.set_buff_icon("@@0@@")
	tomy_ElementalWrath.set_buff_modifier(modifier)
	tomy_ElementalWrath.set_buff_tooltip("Elemental Wrath\nThis unit has Elemental Wrath; it's trigger chance is increased")


func on_attack(_event: Event):
	var tower: Tower = self

	if !tower.calc_chance(_stats.elemental_wrath_chance):
		return

	if tower.get_buff_of_type(tomy_ElementalWrath) == null:
		tomy_ElementalWrath.apply_custom_timed(tower, tower, 150 + tower.get_level() * _stats.trigger_chance_add, 5.0 + 0.1 * tower.get_level())


func on_damage(event: Event):
	var tower: Tower = self

	var target: Creep = event.get_target()
	var immune: bool = target.is_immune()
	var sif: bool = target.get_armor_type() == ArmorType.enm.SIF
	var zod: bool = target.get_armor_type() == ArmorType.enm.ZOD
	var damage_add: float
	var pos_damage_types: float = 3.0

	if immune:
		pos_damage_types = 2.0

	if Utils.rand_chance(0.5):
		if sif || zod:
			damage_add = 1.0
		elif tower.calc_chance(1.0 / pos_damage_types):
			damage_add = 1.8
		elif !immune && tower.calc_chance(1.0 / (pos_damage_types - 1)):
			damage_add = 1.5
		else:
			damage_add = 1.2
	else:
		if zod:
			damage_add = 0.9
		elif sif:
			if !immune || (immune && tower.calc_chance(0.5)):
				damage_add = 0.4
			else:
				damage_add = 0.0
		elif tower.calc_chance(1.0 / (6.0 - pos_damage_types)):
			damage_add = 1.0
		elif tower.calc_chance(1.0 / (6.0 - (pos_damage_types + 1))):
			damage_add = 0.9
		elif !immune || (immune && tower.calc_chance(1.0 / (6.0 - (pos_damage_types + 2)))):
			damage_add = 0.6
		else:
			damage_add = 0.0

	event.damage = event.damage * damage_add

	if damage_add > 1.0:
		tower.get_player().display_small_floating_text(Utils.format_float(damage_add, 2), tower, 0, 255, 0, 40)
	elif damage_add < 1.0:
		tower.get_player().display_small_floating_text(Utils.format_float(damage_add, 2), tower, 255, 0, 0, 40)
	else:
		tower.get_player().display_small_floating_text(Utils.format_float(damage_add, 2), tower, 255, 255, 255, 40)
