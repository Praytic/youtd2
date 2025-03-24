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
	concussive_creep_bt.set_buff_tooltip(tr("PP9O"))

	acid_creep_bt = BuffType.new("acid_creep_bt", ACID_DURATION, 0, false, self)
	var dave_acid_creep_mod: Modifier = Modifier.new()
	dave_acid_creep_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -_stats.acid_mod_armor, -_stats.acid_mod_armor_add)
	acid_creep_bt.set_buff_modifier(dave_acid_creep_mod)
	acid_creep_bt.set_buff_icon("res://resources/icons/generic_icons/open_wound.tres")
	acid_creep_bt.set_buff_tooltip(tr("SLZT"))

	concussive_tower_bt = BuffType.new("concussive_tower_bt", -1, 0, true, self)
	concussive_tower_bt.set_buff_icon("res://resources/icons/generic_icons/rss.tres")
	concussive_tower_bt.set_buff_tooltip(tr("UX05"))

	acid_tower_bt = BuffType.new("acid_tower_bt", -1, 0, true, self)
	acid_tower_bt.set_buff_icon("res://resources/icons/generic_icons/poison_gas.tres")
	acid_tower_bt.set_buff_tooltip(tr("HJG8"))

	smoke_tower_bt = BuffType.new("smoke_tower_bt", -1, 0, true, self)
	smoke_tower_bt.set_buff_icon("res://resources/icons/generic_icons/burning_meteor.tres")
	smoke_tower_bt.set_buff_tooltip(tr("JFQ6"))


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
	
		Effect.create_scaled("res://src/effects/thunder_clap.tscn", Vector3(main_target.get_x(), main_target.get_y(), 0), 0, 1.0)
	elif is_acid:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break
			acid_creep_bt.apply(tower, creep, level)

		var effect: int = Effect.create_scaled("res://src/effects/thunder_clap.tscn", Vector3(main_target.get_x(), main_target.get_y(), 0), 0, 0.8)
		Effect.set_color(effect, Color.GREEN)
	elif is_smoke:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break

			var buff_duration: float = _stats.smoke_duration + _stats.smoke_duration_add * level
			silence_bt.apply_only_timed(tower, creep, buff_duration)

		var effect: int = Effect.create_scaled("res://src/effects/cloud_of_fog_small.tscn", Vector3(main_target.get_x(), main_target.get_y(), 0), 0, 0.8)
		Effect.set_lifetime(effect, 0.5)


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
