extends TowerBehavior


var wrath_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {self_trigger_chances = 0.005, wrath_mod_trigger_chances_add = 0.005, elemental_wrath_chance = 0.150},
		2: {self_trigger_chances = 0.006, wrath_mod_trigger_chances_add = 0.006, elemental_wrath_chance = 0.175},
		3: {self_trigger_chances = 0.007, wrath_mod_trigger_chances_add = 0.007, elemental_wrath_chance = 0.200},
		4: {self_trigger_chances = 0.008, wrath_mod_trigger_chances_add = 0.008, elemental_wrath_chance = 0.225},
		5: {self_trigger_chances = 0.009, wrath_mod_trigger_chances_add = 0.009, elemental_wrath_chance = 0.250},
	}


var BUFF_DURATION: float = 5.0
var BUFF_DURATION_ADD: float = 0.1
var WRATH_MOD_TRIGGER_CHANCES: float = 0.15


func get_ability_info_list_DELETEME() -> Array[AbilityInfo]:
	var buff_duration: String = Utils.format_float(BUFF_DURATION, 2)
	var buff_duration_add: String = Utils.format_float(BUFF_DURATION_ADD, 2)
	var wrath_mod_trigger_chances: String = Utils.format_percent(WRATH_MOD_TRIGGER_CHANCES, 2)
	var wrath_mod_trigger_chances_add: String = Utils.format_percent(_stats.wrath_mod_trigger_chances_add, 2)
	var elemental_wrath_chance: String = Utils.format_percent(_stats.elemental_wrath_chance, 2)

	var list: Array[AbilityInfo] = []
	
	var elemental_wrath: AbilityInfo = AbilityInfo.new()
	elemental_wrath.name = "Elemental Wrath"
	elemental_wrath.icon = "res://resources/icons/scrolls/scroll_04.tres"
	elemental_wrath.description_short = "The Ghost has a chance on attack to increase its trigger chance temporarily.\n"
	elemental_wrath.description_full = "The Elemental Ghost has a %s chance to unleash it's wrath on attack, increasing its trigger chance by %s for %s seconds. Cannot retrigger during Elemental Wrath.\n" % [elemental_wrath_chance, wrath_mod_trigger_chances, buff_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds duration\n" % buff_duration_add \
	+ "+%s trigger chance increase\n" % wrath_mod_trigger_chances_add
	list.append(elemental_wrath)

	var mimic: AbilityInfo = AbilityInfo.new()
	mimic.name = "Mimic"
	mimic.icon = "res://resources/icons/orbs/orb_ice_melting.tres"
	mimic.description_short = "The Ghost is able to deal different damage types.\n"
	mimic.description_full = "The Ghost's attacks are varied, and its damage type will either be good or bad against its target. Trigger chance adjusts the good/bad attacks to be better.\n"
	list.append(mimic)

	return list


func load_triggers(triggers: BuffType):
	triggers.add_event_on_attack(on_attack)
	triggers.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, 0.0, _stats.self_trigger_chances)


func tower_init():
	var modifier: Modifier = Modifier.new()
	modifier.add_modification(Modification.Type.MOD_TRIGGER_CHANCES, WRATH_MOD_TRIGGER_CHANCES, _stats.wrath_mod_trigger_chances_add)
	wrath_bt = BuffType.new("wrath_bt", BUFF_DURATION, BUFF_DURATION_ADD, true, self)
	wrath_bt.set_buff_icon("res://resources/icons/generic_icons/holy_grail.tres")
	wrath_bt.set_buff_modifier(modifier)
	wrath_bt.set_buff_tooltip("Elemental Wrath\nIncreases trigger chances.")


func on_attack(_event: Event):
	if !tower.calc_chance(_stats.elemental_wrath_chance):
		return

	if tower.get_buff_of_type(wrath_bt) == null:
		CombatLog.log_ability(tower, null, "Elemental Wrath")

		var level: int = tower.get_level()

		wrath_bt.apply(tower, tower, level)


func on_damage(event: Event):
	var target: Creep = event.get_target()
	var immune: bool = target.is_immune()
	var sif: bool = target.get_armor_type() == ArmorType.enm.SIF
	var zod: bool = target.get_armor_type() == ArmorType.enm.ZOD
	var damage_add: float
	var pos_damage_types: float = 3.0

	if immune:
		pos_damage_types = 2.0

	if Utils.rand_chance(Globals.synced_rng, 0.5):
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
		tower.get_player().display_small_floating_text(Utils.format_float(damage_add, 2), tower, Color8(0, 255, 0), 40)
	elif damage_add < 1.0:
		tower.get_player().display_small_floating_text(Utils.format_float(damage_add, 2), tower, Color8(255, 0, 0), 40)
	else:
		tower.get_player().display_small_floating_text(Utils.format_float(damage_add, 2), tower, Color8(255, 255, 255), 40)
