extends Tower


var cassim_armor: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {splash_125_damage = 0.45, splash_225_damage = 0.15, armor_decrease = 2},
		2: {splash_125_damage = 0.45, splash_225_damage = 0.20, armor_decrease = 3},
		3: {splash_125_damage = 0.50, splash_225_damage = 0.25, armor_decrease = 5},
		4: {splash_125_damage = 0.50, splash_225_damage = 0.30, armor_decrease = 7},
		5: {splash_125_damage = 0.55, splash_225_damage = 0.35, armor_decrease = 10},
	}


func get_ability_description() -> String:
	var armor_decrease: String = Utils.format_float(_stats.armor_decrease, 2)

	var text: String = ""

	text += "[color=GOLD]Afterglow[/color]\n"
	text += "The Orb has a 5%% chance to reduce armor of units it damages by %s for 5 seconds. This chance is doubled for bosses.\n" % armor_decrease
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+0.6% chance\n"
	text += "+0.25 seconds duration"

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func load_specials(modifier: Modifier):
	var splash_map: Dictionary = {
		125: _stats.splash_125_damage,
		225: _stats.splash_225_damage,
	}
	_set_attack_style_splash(splash_map)

	modifier.add_modification(Modification.Type.MOD_DMG_TO_UNDEAD, 0.15, 0.0)


func tower_init():
	var armor: Modifier = Modifier.new()
	armor.add_modification(Modification.Type.MOD_ARMOR, 0, -1)
	cassim_armor = BuffType.new("cassim_armor", 0, 0, false, self)
	cassim_armor.set_buff_icon("@@0@@")
	cassim_armor.set_buff_modifier(armor)
	cassim_armor.set_stacking_group("astral_armor")

	cassim_armor.set_buff_tooltip("Blinded\nThis unit has been Blinded; it has reduced armor.")


func on_damage(event: Event):
	var tower = self

	var lvl: int = tower.get_level()
	var creep: Unit = event.get_target()
	var size_factor: float = 1.0

	if creep.get_size() == CreepSize.enm.BOSS:
		size_factor = 2.0

	if tower.calc_chance((0.05 + lvl * 0.006) * size_factor):
		cassim_armor.apply_custom_timed(tower, creep, _stats.armor_decrease, 5 + lvl * 0.25)
