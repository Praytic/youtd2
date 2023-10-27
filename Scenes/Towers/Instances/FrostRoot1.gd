extends Tower


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 25, damage_add = 1},
		2: {damage = 125, damage_add = 5},
		3: {damage = 375, damage_add = 15},
		4: {damage = 750, damage_add = 30},
		5: {damage = 1500, damage_add = 60},
		6: {damage = 2500, damage_add = 100},
	}


func get_ability_description() -> String:
	var damage: String = Utils.format_float(_stats.damage, 2)
	var damage_add: String = Utils.format_float(_stats.damage_add, 2)

	var text: String = ""

	text += "[color=GOLD]Frozen Thorn[/color]\n"
	text += "Has a 15%% chance to deal %s additional spell damage each time it deals damage.\n" % damage
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s spell damage" % damage_add

	return text


func load_triggers(triggers_buff_type: BuffType):
	triggers_buff_type.add_event_on_damage(on_damage)


func on_damage(event: Event):
	var tower = self

	if event.is_main_target() && tower.calc_chance(0.15) && !event.get_target().is_immune():
		SFX.sfx_at_unit("Abilities\\Spells\\Undead\\FrostArmor\\FrostArmorDamage.mdl", event.get_target())
		tower.do_spell_damage(event.get_target(), _stats.damage + _stats.damage_add * get_level(), tower.calc_spell_crit_no_bonus())
