extends TowerBehavior


var silence_bt: BuffType
var concussive_tower_bt: BuffType
var concussive_creep_bt: BuffType
var acid_tower_bt: BuffType
var acid_creep_bt: BuffType
var smoke_tower_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bomb_radius = 250, concussive_mod_movespeed = 0.15, concussive_mod_movespeed_add = 0.004, acid_mod_armor = 0.10, acid_mod_armor_add = 0.004, smoke_duration = 1.0, smoke_duration_add = 0.04},
		2: {bomb_radius = 300, concussive_mod_movespeed = 0.25, concussive_mod_movespeed_add = 0.006, acid_mod_armor = 0.15, acid_mod_armor_add = 0.006, smoke_duration = 1.5, smoke_duration_add = 0.06},
	}

const CONCUSSIVE_DURATION: float = 4.0
const ACID_DURATION: float = 4.0


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	silence_bt = CbSilence.new("silence_bt", 0, 0, false, self)

	concussive_creep_bt = BuffType.new("concussive_creep_bt", CONCUSSIVE_DURATION, 0, false, self)
	var dave_concussive_creep_mod: Modifier = Modifier.new()
	dave_concussive_creep_mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.concussive_mod_movespeed, -_stats.concussive_mod_movespeed_add)
	concussive_creep_bt.set_buff_modifier(dave_concussive_creep_mod)
	concussive_creep_bt.set_buff_icon("res://resources/icons/generic_icons/foot_trip.tres")
	concussive_creep_bt.set_buff_tooltip("Concussion\nReduces movement speed.")

	acid_creep_bt = BuffType.new("acid_creep_bt", ACID_DURATION, 0, false, self)
	var dave_acid_creep_mod: Modifier = Modifier.new()
	dave_acid_creep_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -_stats.acid_mod_armor, -_stats.acid_mod_armor_add)
	acid_creep_bt.set_buff_modifier(dave_acid_creep_mod)
	acid_creep_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	acid_creep_bt.set_buff_tooltip("Acid Corrosion\nReduces armor.")

	concussive_tower_bt = BuffType.new("concussive_tower_bt", -1, 0, true, self)
	concussive_tower_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	concussive_tower_bt.set_buff_tooltip("Concussive Bombs\nEach attack slows creeps around the target.")

	acid_tower_bt = BuffType.new("acid_tower_bt", -1, 0, true, self)
	acid_tower_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	acid_tower_bt.set_buff_tooltip("Acid Bombs\nEach attack reduces the armor of creeps around the target.")

	smoke_tower_bt = BuffType.new("smoke_tower_bt", -1, 0, true, self)
	smoke_tower_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	smoke_tower_bt.set_buff_tooltip("Smoke Bombs\nEach attack silences creeps around the target.")


func create_autocasts() -> Array[Autocast]:
	var list: Array[Autocast] = []

	var bomb_radius: String = Utils.format_float(_stats.bomb_radius, 2)

	var concussive_mod_movespeed: String = Utils.format_percent(_stats.concussive_mod_movespeed, 2)
	var concussive_mod_movespeed_add: String = Utils.format_percent(_stats.concussive_mod_movespeed_add, 2)
	var concussive_duration: String = Utils.format_float(CONCUSSIVE_DURATION, 2)

	var acid_mod_armor: String = Utils.format_percent(_stats.acid_mod_armor, 2)
	var acid_mod_armor_add: String = Utils.format_percent(_stats.acid_mod_armor_add, 2)
	var acid_duration: String = Utils.format_float(ACID_DURATION, 2)

	var smoke_duration: String = Utils.format_float(_stats.smoke_duration, 2)
	var smoke_duration_add: String = Utils.format_float(_stats.smoke_duration_add, 2)

	var autocast_concussive: Autocast = Autocast.make()
	autocast_concussive.title = "Concussive Bombs"
	autocast_concussive.icon = "res://resources/icons/orbs/orb_molten_dull.tres"
	autocast_concussive.description_short = "Equips the tower with concussive bombs.\n"
	autocast_concussive.description = "Equips the tower with concussive bombs. Each attack slows all the creeps in a %s area around the target by %s for %s seconds.\n" % [bomb_radius, concussive_mod_movespeed, concussive_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s slow\n" % concussive_mod_movespeed_add
	autocast_concussive.caster_art = ""
	autocast_concussive.target_art = ""
	autocast_concussive.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_concussive.num_buffs_before_idle = 1
	autocast_concussive.cast_range = 0
	autocast_concussive.auto_range = 0
	autocast_concussive.cooldown = 5
	autocast_concussive.mana_cost = 0
	autocast_concussive.target_self = true
	autocast_concussive.is_extended = false
	autocast_concussive.buff_type = concussive_tower_bt
	autocast_concussive.buff_target_type = null
	autocast_concussive.handler = on_autocast_concussive
	list.append(autocast_concussive)

	var autocast_acid: Autocast = Autocast.make()
	autocast_acid.title = "Acid Bombs"
	autocast_acid.icon = "res://resources/icons/fire/fire_bowl_03.tres"
	autocast_acid.description_short = "Equips the tower with acid bombs.\n"
	autocast_acid.description = "Equips the tower with acid bombs. Each attack reduces the armor of all the creeps in a %s area around the target by %s for %s seconds.\n" % [bomb_radius, acid_mod_armor, acid_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s armor reduction\n" % acid_mod_armor_add
	autocast_acid.caster_art = ""
	autocast_acid.target_art = ""
	autocast_acid.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_acid.num_buffs_before_idle = 1
	autocast_acid.cast_range = 0
	autocast_acid.auto_range = 0
	autocast_acid.cooldown = 5
	autocast_acid.mana_cost = 0
	autocast_acid.target_self = true
	autocast_acid.is_extended = false
	autocast_acid.buff_type = acid_tower_bt
	autocast_acid.buff_target_type = null
	autocast_acid.handler = on_autocast_acid
	list.append(autocast_acid)

	var autocast_smoke: Autocast = Autocast.make()
	autocast_smoke.title = "Smoke Bombs"
	autocast_smoke.icon = "res://resources/icons/misc/balls_02.tres"
	autocast_smoke.description_short = "Equips the tower with smoke bombs.\n"
	autocast_smoke.description = "Equips the tower with smoke bombs. Each attack silences all the creeps in a %s area around the target for %s second.\n" % [bomb_radius, smoke_duration] \
	+ " \n" \
	+ "[color=ORANGE]Level Bonus:[/color]\n" \
	+ "+%s seconds duration\n" % smoke_duration_add
	autocast_smoke.caster_art = ""
	autocast_smoke.target_art = ""
	autocast_smoke.autocast_type = Autocast.Type.AC_TYPE_NOAC_IMMEDIATE
	autocast_smoke.num_buffs_before_idle = 1
	autocast_smoke.cast_range = 0
	autocast_smoke.auto_range = 0
	autocast_smoke.cooldown = 5
	autocast_smoke.mana_cost = 0
	autocast_smoke.target_self = true
	autocast_smoke.is_extended = false
	autocast_smoke.buff_type = smoke_tower_bt
	autocast_smoke.buff_target_type = null
	autocast_smoke.handler = on_autocast_smoke
	list.append(autocast_smoke)

	return list


func on_damage(event: Event):
	var level: int = tower.get_level()
	var main_target: Unit = event.get_target()
	var is_concussive: bool = tower.get_buff_of_type(concussive_tower_bt) != null
	var is_acid: bool = tower.get_buff_of_type(acid_tower_bt) != null
	var is_smoke: bool = tower.get_buff_of_type(smoke_tower_bt) != null
	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), main_target, _stats.bomb_radius)

	if is_concussive:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break
			concussive_creep_bt.apply(tower, creep, level)
	
		var effect: int = Effect.create_scaled("res://src/effects/bdragon_466_thunderclap.tscn", Vector3(main_target.get_x(), main_target.get_y(), 0), 0, 1.0)
		Effect.destroy_effect_after_its_over(effect)
	elif is_acid:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break
			acid_creep_bt.apply(tower, creep, level)

		var effect: int = Effect.create_scaled("res://src/effects/bdragon_466_thunderclap.tscn", Vector3(main_target.get_x(), main_target.get_y(), 0), 0, 0.8)
		Effect.set_color(effect, Color.GREEN)
		Effect.destroy_effect_after_its_over(effect)
	elif is_smoke:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break

			var buff_duration: float = _stats.smoke_duration + _stats.smoke_duration_add * level
			silence_bt.apply_only_timed(tower, creep, buff_duration)

		var effect: int = Effect.create_scaled("res://src/effects/bdragon_519_expanding_puff.tscn", Vector3(main_target.get_x(), main_target.get_y(), 0), 0, 0.8)
		Effect.set_color(effect, Color.BROWN)
		Effect.destroy_effect_after_its_over(effect)


func on_autocast_concussive(_event: Event):
	switch_bomb_type(concussive_tower_bt)


func on_autocast_acid(_event: Event):
	switch_bomb_type(acid_tower_bt)


func on_autocast_smoke(_event: Event):
	switch_bomb_type(smoke_tower_bt)


func switch_bomb_type(new_bomb_bt: BuffType):
# 	Remove current bomb
	var bomb_bt_list: Array[BuffType] = [
		concussive_tower_bt,
		acid_tower_bt,
		smoke_tower_bt,
	]
	bomb_bt_list.erase(new_bomb_bt)
	for bomb_bt in bomb_bt_list:
		var active_buff: Buff = tower.get_buff_of_type(bomb_bt)
		if active_buff != null:
			active_buff.remove_buff()

# 	Switch to new bomb
	if tower.get_buff_of_type(new_bomb_bt) == null:
		new_bomb_bt.apply(tower, tower, tower.get_level())
