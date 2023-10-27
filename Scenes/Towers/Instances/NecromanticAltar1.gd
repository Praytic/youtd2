extends Tower


# NOTE: simplified original script because it didn't use
# Iterate.next_random().


func get_tier_stats() -> Dictionary:
	return {
		1: {damage = 200, damage_add = 12},
		2: {damage = 400, damage_add = 24},
		3: {damage = 800, damage_add = 48},
		4: {damage = 1700, damage_add = 100},
	}


func get_autocast_description() -> String:
	var damage_1: String = Utils.format_float(_stats.damage, 2)
	var damage_2: String = Utils.format_float(_stats.damage * 2, 2)
	var damage_3: String = Utils.format_float(_stats.damage * 3, 2)
	var damage_add_1: String = Utils.format_float(_stats.damage_add, 2)
	var damage_add_2: String = Utils.format_float(_stats.damage_add * 2, 2)
	var damage_add_3: String = Utils.format_float(_stats.damage_add * 3, 2)

	var text: String = ""

	text += "Hits 3 random creeps in 875 range, the first one suffers %s spelldamage, the second one suffers %s spelldamage and the third one suffers %s spelldamage.\n" % [damage_1, damage_2, damage_3]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s/%s/%s spelldamage\n" % [damage_add_1, damage_add_2, damage_add_3]

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Hits 3 random creeps with dark powers.\n"

	return text


func tower_init():
	var autocast: Autocast = Autocast.make()
	autocast.title = "Soul Revenge"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://Resources/Textures/UI/Icons/gold_icon.tres"
	autocast.caster_art = ""
	autocast.num_buffs_before_idle = 0
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_IMMEDIATE
	autocast.cast_range = 875
	autocast.target_self = false
	autocast.target_art = ""
	autocast.cooldown = 1
	autocast.is_extended = false
	autocast.mana_cost = 20
	autocast.buff_type = null
	autocast.target_type = null
	autocast.auto_range = 875
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(_event: Event):
	var tower: Tower = self
	var lvl: int = tower.get_level()
	var iterate: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 875)
	var next: Unit
	var loop_counter: int = 3
	var counter: int = 3

	while true:
		loop_counter = loop_counter - 1
		next = iterate.next_random()

		if next == null:
			break

		tower.do_spell_damage(next, (_stats.damage + lvl * _stats.damage_add) * counter, tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("AlreTarget.mdl", next)
		counter = counter + 1

		if loop_counter == 0:
			break
