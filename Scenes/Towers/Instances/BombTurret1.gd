extends Tower


var cb_silence: BuffType
var dave_concussive_tower_bt: BuffType
var dave_concussive_creep_bt: BuffType
var dave_acid_tower_bt: BuffType
var dave_acid_creep_bt: BuffType
var dave_smoke_tower_bt: BuffType


func get_tier_stats() -> Dictionary:
	return {
		1: {bomb_radius = 250, concussive_mod_movespeed = 0.15, concussive_mod_movespeed_add = 0.004, acid_mod_armor = 0.10, acid_mod_armor_add = 0.004, smoke_duration = 1.0, smoke_duration_add = 0.04},
		2: {bomb_radius = 300, concussive_mod_movespeed = 0.25, concussive_mod_movespeed_add = 0.006, acid_mod_armor = 0.15, acid_mod_armor_add = 0.006, smoke_duration = 1.5, smoke_duration_add = 0.06},
	}

const CONCUSSIVE_DURATION: float = 4.0
const ACID_DURATION: float = 4.0


func get_autocast_description_concussive() -> String:
	var bomb_radius: String = Utils.format_float(_stats.bomb_radius, 2)
	var concussive_mod_movespeed: String = Utils.format_percent(_stats.concussive_mod_movespeed, 2)
	var concussive_mod_movespeed_add: String = Utils.format_percent(_stats.concussive_mod_movespeed_add, 2)
	var concussive_duration: String = Utils.format_float(CONCUSSIVE_DURATION, 2)

	var text: String = ""

	text += "Equips the tower with concussive bombs. Each attack slows all the creeps in a %s area around the target by %s for %s seconds.\n" % [bomb_radius, concussive_mod_movespeed, concussive_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s slow\n" % concussive_mod_movespeed_add

	return text


func get_autocast_description_acid() -> String:
	var bomb_radius: String = Utils.format_float(_stats.bomb_radius, 2)
	var acid_mod_armor: String = Utils.format_percent(_stats.acid_mod_armor, 2)
	var acid_mod_armor_add: String = Utils.format_percent(_stats.acid_mod_armor_add, 2)
	var acid_duration: String = Utils.format_float(ACID_DURATION, 2)

	var text: String = ""

	text += "Equips the tower with acid bombs. Each attack reduces the armor of all the creeps in a %s area around the target by %s for %s seconds.\n" % [bomb_radius, acid_mod_armor, acid_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s armor reduction\n" % acid_mod_armor_add

	return text


func get_autocast_description_smoke() -> String:
	var bomb_radius: String = Utils.format_float(_stats.bomb_radius, 2)
	var smoke_duration: String = Utils.format_float(_stats.smoke_duration, 2)
	var smoke_duration_add: String = Utils.format_float(_stats.smoke_duration_add, 2)

	var text: String = ""

	text += "Equips the tower with smoke bombs. Each attack silences all the creeps in a %s area around the target for %s second.\n" % [bomb_radius, smoke_duration]
	text += " \n"
	text += "[color=ORANGE]Level Bonus:[/color]\n"
	text += "+%s seconds duration\n" % smoke_duration_add

	return text


func load_triggers(triggers: BuffType):
	triggers.add_event_on_damage(on_damage)


func tower_init():
	cb_silence = CbSilence.new("bomb_turret_silence", 0, 0, false, self)

	dave_concussive_creep_bt = BuffType.new("dave_concussive_creep_bt", CONCUSSIVE_DURATION, 0, false, self)
	var dave_concussive_creep_mod: Modifier = Modifier.new()
	dave_concussive_creep_mod.add_modification(Modification.Type.MOD_MOVESPEED, -_stats.concussive_mod_movespeed, -_stats.concussive_mod_movespeed_add)
	dave_concussive_creep_bt.set_buff_modifier(dave_concussive_creep_mod)
	dave_concussive_creep_bt.set_buff_icon("@@2@@")
	dave_concussive_creep_bt.set_buff_tooltip("Concussion\nThis unit has Concussion; it has reduced movement speed.")

	dave_acid_creep_bt = BuffType.new("dave_acid_creep_bt", ACID_DURATION, 0, false, self)
	var dave_acid_creep_mod: Modifier = Modifier.new()
	dave_acid_creep_mod.add_modification(Modification.Type.MOD_ARMOR_PERC, -_stats.acid_mod_armor, -_stats.acid_mod_armor_add)
	dave_acid_creep_bt.set_buff_modifier(dave_acid_creep_mod)
	dave_acid_creep_bt.set_buff_icon("@@4@@")
	dave_acid_creep_bt.set_buff_tooltip("Acid Corrosion\nThis unit is covered in acid; it has reduced armor.")

	dave_concussive_tower_bt = BuffType.new("dave_concussive_tower_bt", -1, 0, true, self)
	dave_concussive_tower_bt.set_buff_icon("@@0@@")
	dave_concussive_tower_bt.set_buff_tooltip("Concussive Bombs\nThis tower is equiped with Concussive Bombs; each attack slows creeps around the target.")

	dave_acid_tower_bt = BuffType.new("dave_acid_tower_bt", -1, 0, true, self)
	dave_acid_tower_bt.set_buff_icon("@@1@@")
	dave_acid_tower_bt.set_buff_tooltip("Acid Bombs\nThis tower is equiped with Acid Bombs; each attack reduces the armor of creeps around the target.")

	dave_smoke_tower_bt = BuffType.new("dave_smoke_tower_bt", -1, 0, true, self)
	dave_smoke_tower_bt.set_buff_icon("@@3@@")
	dave_smoke_tower_bt.set_buff_tooltip("Acid Bombs\nThis tower is equiped with Smoke Bombs; each attack silences creeps around the target.")

	var autocast_concussive: Autocast = Autocast.make()
	autocast_concussive.title = "Concussive Bombs"
	autocast_concussive.description = get_autocast_description_concussive()
	autocast_concussive.icon = "res://path/to/icon.png"
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
	autocast_concussive.buff_type = dave_concussive_tower_bt
	autocast_concussive.target_type = TargetType.new(TargetType.TOWERS)
	autocast_concussive.handler = on_autocast_concussive
	add_autocast(autocast_concussive)

	var autocast_acid: Autocast = Autocast.make()
	autocast_acid.title = "Acid Bombs"
	autocast_acid.description = get_autocast_description_acid()
	autocast_acid.icon = "res://path/to/icon.png"
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
	autocast_acid.buff_type = dave_acid_tower_bt
	autocast_acid.target_type = TargetType.new(TargetType.TOWERS)
	autocast_acid.handler = on_autocast_acid
	add_autocast(autocast_acid)

	var autocast_smoke: Autocast = Autocast.make()
	autocast_smoke.title = "Acid Bombs"
	autocast_smoke.description = get_autocast_description_smoke()
	autocast_smoke.icon = "res://path/to/icon.png"
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
	autocast_smoke.buff_type = dave_smoke_tower_bt
	autocast_smoke.target_type = TargetType.new(TargetType.TOWERS)
	autocast_smoke.handler = on_autocast_smoke
	add_autocast(autocast_smoke)


func on_damage(event: Event):
	var tower: Tower = self
	var level: int = tower.get_level()
	var main_target: Unit = event.get_target()
	var is_concussive: bool = tower.get_buff_of_type(dave_concussive_tower_bt) != null
	var is_acid: bool = tower.get_buff_of_type(dave_acid_tower_bt) != null
	var is_smoke: bool = tower.get_buff_of_type(dave_smoke_tower_bt) != null
	var creeps_in_range: Iterate = Iterate.over_units_in_range_of_unit(tower, TargetType.new(TargetType.CREEPS), main_target, _stats.bomb_radius)

	if is_concussive:
		print("is_concussive")
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break
			dave_concussive_creep_bt.apply(tower, creep, level)
	
		var effect: int = Effect.create_scaled("ThunderClapCaster.mdl", main_target.get_visual_x(), main_target.get_visual_y(), 0, 0, 1.0)
		Effect.set_lifetime(effect, 0.2)
	elif is_acid:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break
			dave_acid_creep_bt.apply(tower, creep, level)

		var effect: int = Effect.create_scaled("ThunderClapCaster.mdl", main_target.get_visual_x(), main_target.get_visual_y(), 0, 0, 1.3)
		Effect.set_lifetime(effect, 0.2)
	elif is_smoke:
		while true:
			var creep: Unit = creeps_in_range.next()
			if creep == null:
				break

			var buff_duration: float = _stats.smoke_duration + _stats.smoke_duration_add * level
			cb_silence.apply_only_timed(tower, creep, buff_duration)

		var effect: int = Effect.create_scaled("CloudOfFog.mdl", main_target.get_visual_x(), main_target.get_visual_y(), 0, 0, 0.8)
		Effect.set_lifetime(effect, 0.5)


func on_autocast_concussive(_event: Event):
	print("on_autocast_concussive")
	switch_bomb_type(dave_concussive_tower_bt)


func on_autocast_acid(_event: Event):
	switch_bomb_type(dave_acid_tower_bt)


func on_autocast_smoke(_event: Event):
	switch_bomb_type(dave_smoke_tower_bt)


func switch_bomb_type(new_bomb_bt: BuffType):
	var tower: Tower = self

# 	Remove current bomb
	var bomb_bt_list: Array[BuffType] = [
		dave_concussive_tower_bt,
		dave_acid_tower_bt,
		dave_smoke_tower_bt,
	]
	bomb_bt_list.erase(new_bomb_bt)
	for bomb_bt in bomb_bt_list:
		var active_buff: Buff = tower.get_buff_of_type(bomb_bt)
		if active_buff != null:
			active_buff.remove_buff()

# 	Switch to new bomb
	if tower.get_buff_of_type(new_bomb_bt) == null:
		new_bomb_bt.apply(tower, tower, tower.get_level())


