extends Tower


var multiboard: MultiboardValues


func get_tier_stats() -> Dictionary:
	return {
		1: {base_damage = 1450, base_damage_add = 58, damage_per_tower = 435, damage_per_tower_add = 17.4},
		2: {base_damage = 2900, base_damage_add = 116, damage_per_tower = 870, damage_per_tower_add = 34.8},
		3: {base_damage = 4350, base_damage_add = 174, damage_per_tower = 1305, damage_per_tower_add = 52.2},
	}

const RECAST_CHANCE: float = 0.25


func get_autocast_description() -> String:
	var recast_chance: String = Utils.format_percent(RECAST_CHANCE, 2)
	var base_damage: String = Utils.format_float(_stats.base_damage, 2)
	var base_damage_add: String = Utils.format_float(_stats.base_damage_add, 2)
	var damage_per_tower: String = Utils.format_float(_stats.damage_per_tower, 2)
	var damage_per_tower_add: String = Utils.format_float(_stats.damage_per_tower_add, 2)

	var text: String = ""

	text += "Deals [%s + (%s x amount of player towers)] spell damage to a target creep. This ability has a %s chance to recast itself when cast. Maximum of 1 extra cast.\n" % [base_damage, damage_per_tower, recast_chance]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s base spelldamage\n" % base_damage_add
	text += "+%s spelldamage per player tower\n" % damage_per_tower_add
	text += "+1 extra cast at levels 15 and 25\n"

	return text


func get_autocast_description_short() -> String:
	var text: String = ""

	text += "Releases a strong lightning on the target."

	return text


func tower_init():
	multiboard = MultiboardValues.new(1)
	multiboard.set_key(0, "Thunder Shock Dmg")

	var autocast: Autocast = Autocast.make()
	autocast.title = "Thunder Shock"
	autocast.description = get_autocast_description()
	autocast.description_short = get_autocast_description_short()
	autocast.icon = "res://path/to/icon.png"
	autocast.caster_art = "PurgeBuffTarget.mdl"
	autocast.target_art = ""
	autocast.autocast_type = Autocast.Type.AC_TYPE_OFFENSIVE_UNIT
	autocast.num_buffs_before_idle = 1
	autocast.cast_range = 1200
	autocast.auto_range = 1200
	autocast.cooldown = 3
	autocast.mana_cost = 12
	autocast.target_self = true
	autocast.is_extended = false
	autocast.buff_type = null
	autocast.target_type = TargetType.new(TargetType.CREEPS)
	autocast.handler = on_autocast
	add_autocast(autocast)


func on_autocast(event: Event):
	var tower: Tower = self
	var target: Unit = event.get_target()
	var lvl: int = tower.get_level()

	var thunder_shock_damage: float = get_current_thunder_shock_damage()

	tower.do_spell_damage(target, thunder_shock_damage, tower.calc_spell_crit_no_bonus())

	var recast_happened: bool = tower.calc_chance(RECAST_CHANCE)
	if !recast_happened:
		return

	tower.get_player().display_small_floating_text("MULTICAST!", tower, 0, 255, 0, 0.0)

	var cast_count: int
	if lvl == 25:
		cast_count = 3
	elif lvl >= 15:
		cast_count = 2
	else:
		cast_count = 1

	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_caster(tower, TargetType.new(TargetType.CREEPS), 1200)

	while true:
		var creep: Unit = creeps_in_range.next_random()

		if creep == null:
			break

		tower.do_spell_damage(creep, thunder_shock_damage, tower.calc_spell_crit_no_bonus())
		SFX.sfx_at_unit("MonsoonBoltTarget.mdl", creep)

		cast_count -= 1

		if cast_count == 0:
			break


func on_tower_details() -> MultiboardValues:
	var thunder_shock_damage: float = get_current_thunder_shock_damage()
	var thunder_shock_damage_string: String = Utils.format_float(thunder_shock_damage, 2)
	multiboard.set_value(0, thunder_shock_damage_string)

	return multiboard


func get_current_thunder_shock_damage() -> float:
	var tower: Tower = self
	var base_damage: float = _stats.base_damage + _stats.base_damage_add * tower.get_level()
	var damage_per_tower: float = _stats.damage_per_tower + _stats.damage_per_tower_add * tower.get_level()
	var tower_count: int = tower.get_player().get_num_towers()
	var thunder_shock_damage: float = base_damage + damage_per_tower * tower_count

	return thunder_shock_damage
