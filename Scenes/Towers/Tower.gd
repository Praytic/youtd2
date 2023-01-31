class_name Tower
extends Building


# Tower attacks by periodically firing projectiles at mobs
# that are in range.


signal upgraded

enum Stat {
	ATTACK_RANGE,
	ATTACK_CD,
	ATTACK_DAMAGE_MIN,
	ATTACK_DAMAGE_MAX,
	MOD_ATTACK_CRIT_CHANCE,
	MOD_ATTACK_CRIT_DAMAGE,
	MOD_MULTICRIT_COUNT,
	MISS_CHANCE,

	MOD_DMG_TO_MASS,
	MOD_DMG_TO_NORMAL,
	MOD_DMG_TO_CHAMPION,
	MOD_DMG_TO_BOSS,

	MOD_DMG_TO_UNDEAD,
	MOD_DMG_TO_MAGIC,
	MOD_DMG_TO_NATURE,
	MOD_DMG_TO_ORC,
	MOD_DMG_TO_HUMANOID,
}

enum TriggerParameter {
	ON_DAMAGE_CHANCE,
	ON_DAMAGE_CHANCE_LEVEL_ADD,
	ON_ATTACK_CHANCE,
	ON_ATTACK_CHANCE_LEVEL_ADD,
}

export(int) var id
export(int) var next_tier_id

# Mapping of modification type to the tower stat that it
# modifies.
const _modification_type_to_stat_map: Dictionary = {
	Modification.Type.MOD_ATTACK_CRIT_CHANCE: Stat.MOD_ATTACK_CRIT_CHANCE, 
	Modification.Type.MOD_MULTICRIT_COUNT: Stat.MOD_MULTICRIT_COUNT, 

	Modification.Type.MOD_DMG_TO_MASS: Stat.MOD_DMG_TO_MASS, 
	Modification.Type.MOD_DMG_TO_NORMAL: Stat.MOD_DMG_TO_NORMAL, 
	Modification.Type.MOD_DMG_TO_CHAMPION: Stat.MOD_DMG_TO_CHAMPION, 
	Modification.Type.MOD_DMG_TO_BOSS: Stat.MOD_DMG_TO_BOSS, 

	Modification.Type.MOD_DMG_TO_UNDEAD: Stat.MOD_DMG_TO_UNDEAD, 
	Modification.Type.MOD_DMG_TO_MAGIC: Stat.MOD_DMG_TO_MAGIC, 
	Modification.Type.MOD_DMG_TO_NATURE: Stat.MOD_DMG_TO_NATURE, 
	Modification.Type.MOD_DMG_TO_ORC: Stat.MOD_DMG_TO_ORC, 
	Modification.Type.MOD_DMG_TO_HUMANOID: Stat.MOD_DMG_TO_HUMANOID, 
}

const _mob_type_to_stat_map: Dictionary = {
	Mob.Type.UNDEAD: Stat.MOD_DMG_TO_MASS,
	Mob.Type.MAGIC: Stat.MOD_DMG_TO_MAGIC,
	Mob.Type.NATURE: Stat.MOD_DMG_TO_NATURE,
	Mob.Type.ORC: Stat.MOD_DMG_TO_ORC,
	Mob.Type.HUMANOID: Stat.MOD_DMG_TO_HUMANOID,
}

const _mob_size_to_stat_map: Dictionary = {
	Mob.Size.MASS: Stat.MOD_DMG_TO_MASS,
	Mob.Size.NORMAL: Stat.MOD_DMG_TO_NORMAL,
	Mob.Size.CHAMPION: Stat.MOD_DMG_TO_CHAMPION,
	Mob.Size.BOSS: Stat.MOD_DMG_TO_BOSS,
}

# NOTE: crit damage default means the default bonus damage
# from crits, so default value of 1.0 means +100%
const CRIT_DAMAGE_DEFAULT: float = 1.0
const CRIT_CHANCE_DEFAULT: float = 0.0
const MULTICRIT_COUNT_DEFAULT: int = 1

var _attack_type: String
var _ingame_name: String
var _author: String
var _rarity: String
var _element: String
var _splash: Dictionary
var _cost: float
var _description: String
var _target_mob: Mob = null
var _aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")
var _projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var _stat_map: Dictionary = {
	Stat.ATTACK_RANGE: 0.0,
	Stat.ATTACK_CD: 0.0,
	Stat.ATTACK_DAMAGE_MIN: 0,
	Stat.ATTACK_DAMAGE_MAX: 0,
	Stat.MOD_ATTACK_CRIT_CHANCE: 0.0,
	Stat.MOD_ATTACK_CRIT_DAMAGE: 0.0,
	Stat.MOD_MULTICRIT_COUNT: 0.0,
	Stat.MISS_CHANCE: 0.0,

	Stat.MOD_DMG_TO_MASS: 0.0,
	Stat.MOD_DMG_TO_NORMAL: 0.0,
	Stat.MOD_DMG_TO_CHAMPION: 0.0,
	Stat.MOD_DMG_TO_BOSS: 0.0,

	Stat.MOD_DMG_TO_UNDEAD: 0.0,
	Stat.MOD_DMG_TO_MAGIC: 0.0,
	Stat.MOD_DMG_TO_NATURE: 0.0,
	Stat.MOD_DMG_TO_ORC: 0.0,
	Stat.MOD_DMG_TO_HUMANOID: 0.0,
}
var _trigger_parameters: Dictionary = {
	TriggerParameter.ON_DAMAGE_CHANCE: 1.0,
	TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD: 0.0,
	TriggerParameter.ON_ATTACK_CHANCE: 1.0,
	TriggerParameter.ON_ATTACK_CHANCE_LEVEL_ADD: 0.0,
}


onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var _attack_cooldown_timer: Timer = $AttackCooldownTimer
onready var _targeting_area: Area2D = $TargetingArea


func _ready():
	add_child(_aoe_scene.instance(), true)
	
	var properties: Dictionary = _get_properties()
	_attack_type = properties["attack_type"]
	_ingame_name = properties["name"]
	_author = properties["author"]
	_rarity = properties["rarity"]
	_element = properties["element"]
	_splash = properties["splash"]
	_cost = properties["cost"]
	_description = properties["description"]
	
	var specials_modifier: Modifier = _get_specials_modifier()

	if specials_modifier != null:
		add_modifier(specials_modifier)

# 	NOTE: dicts for stats and trigger parameters may omit
# 	keys for convenience, so need to iterate over keys in
# 	properties to avoid triggering "invalid key" error
	var base_stats: Dictionary = properties["base_stats"]
	
	for stat in base_stats.keys():
		_stat_map[stat] = base_stats[stat]

	var trigger_parameters = properties["trigger_parameters"]

	for parameter in trigger_parameters.keys():
		_trigger_parameters[parameter] = trigger_parameters[parameter]

	_load_stats()

	$AreaOfEffect.hide()

	_attack_cooldown_timer.connect("timeout", self, "_on_AttackCooldownTimer_timeout")
	_attack_cooldown_timer.one_shot = true

	_targeting_area.connect("body_entered", self, "_on_TargetingArea_body_entered")
	_targeting_area.connect("body_exited", self, "_on_TargetingArea_body_exited")


func get_name() -> String:
	return _ingame_name


func build_init():
	.build_init()
	$AreaOfEffect.show()


func upgrade() -> PackedScene:
	var next_tier_tower = TowerManager.get_tower(next_tier_id)
	emit_signal("upgraded")
	return next_tier_tower


func change_level(new_level: int):
	set_level(new_level)

# 	NOTE: stats could've change due to level up so re-load them
	_load_stats()


func _on_AttackCooldownTimer_timeout():
	if !_have_target():
		_target_mob = _find_new_target()
		
	_try_to_attack()


func _on_TargetingArea_body_entered(body):
	if _have_target():
		return
		
	if body is Mob:
#		New target acquired
		_target_mob = body
		_try_to_attack()


func _on_TargetingArea_body_exited(body):
	if body == _target_mob:
#		Target has gone out of range
		_target_mob = _find_new_target()
		_try_to_attack()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func _find_new_target() -> Mob:
	var body_list: Array = _targeting_area.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0
	
	for body in body_list:
		if body is Mob:
			var mob: Mob = body
			var distance: float = (mob.position - self.position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func _try_to_attack():
	if building_in_progress:
		return

	if !_have_target():
		return
	
	var attack_on_cooldown: bool = _attack_cooldown_timer.time_left > 0
	
	if attack_on_cooldown:
		return

	var event: Event = Event.new()
	event.target = _target_mob

	var on_attack_is_called: bool = _get_trigger_is_called(TriggerParameter.ON_ATTACK_CHANCE, TriggerParameter.ON_ATTACK_CHANCE_LEVEL_ADD)

	if on_attack_is_called:
		_on_attack(event)

	if event.can_attack:
		var projectile = _projectile_scene.instance()
		projectile.init(_target_mob, global_position)
		projectile.connect("reached_mob", self, "_on_projectile_reached_mob")
		_game_scene.call_deferred("add_child", projectile)

	_attack_cooldown_timer.start()


func _have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return _target_mob != null and is_instance_valid(_target_mob)


func _select():
	._select()
	print_debug("Tower %s has been selected." % id)


func _unselect():
	._unselect()
	print_debug("Tower %s has been unselected." % id)


func _on_projectile_reached_mob(mob: Mob):
	var is_miss: bool = _get_stat_chance(Stat.MISS_CHANCE)

	if is_miss:
		return

	var damage_base: float = _get_rand_damage_base()

#	NOTE: apply event's damage, so that any changes done by
#	scripts in _on_damage() apply
	_apply_damage_to_mob(mob, damage_base)
	_do_splash_attack(mob, damage_base)


func _do_splash_attack(splash_target: Mob, damage_base: float):
	if _splash.empty():
		return

	var splash_pos: Vector2 = splash_target.position
	var splash_range_list: Array = _splash.keys()
	
#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()
	var mob_list: Array = Utils.get_mob_list_in_range(splash_pos, splash_range_max)

	for mob in mob_list:
		if mob == splash_target:
			continue
		
		var distance: float = splash_pos.distance_to(mob.position)

		for splash_range in splash_range_list:
			var mob_is_in_range: bool = distance < splash_range

			if mob_is_in_range:
				var splash_damage_ratio: float = _splash[splash_range]
				var splash_damage: float = damage_base * splash_damage_ratio
				_apply_damage_to_mob(mob, splash_damage)

				break


# TODO: need to handle application of all bonuses, for both
# normal damage and splash attack and handle bonuses
# incoming from spell scripts
func _apply_damage_to_mob(mob: Mob, damage_base: float):
	var event: Event = Event.new()
	event.damage = _get_damage_to_mob(mob, damage_base)
	event.target = mob

	var on_damage_is_called: bool = _get_trigger_is_called(TriggerParameter.ON_DAMAGE_CHANCE, TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD)

	if on_damage_is_called:
		_on_damage(event)

#	NOTE: apply event's damage, so that any changes done by
#	scripts in _on_damage() apply
	mob.apply_damage(event.damage)


func _get_stat_chance(stat: int) -> bool:
	var chance: float = _stat_map[stat]
	var chance_success: bool = Utils.rand_chance(chance)

	return chance_success


func _load_stats():
	var cast_range: float = _stat_map[Stat.ATTACK_RANGE]
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)
	$AreaOfEffect.set_radius(cast_range)

	var attack_cd: float = _stat_map[Stat.ATTACK_CD]
	_attack_cooldown_timer.wait_time = attack_cd


# NOTE: returns random damage within range without any mods applied
func _get_rand_damage_base() -> float:
	var damage_min: float = _stat_map[Stat.ATTACK_DAMAGE_MIN]
	var damage_max: float = _stat_map[Stat.ATTACK_DAMAGE_MAX]
	var damage: float = rand_range(damage_min, damage_max)

	return damage


func _get_trigger_is_called(trigger_chance: int, trigger_chance_level_add: int) -> bool:
	var chance_base: float = _trigger_parameters[trigger_chance]
	var chance_per_level: float = _trigger_parameters[trigger_chance_level_add]
	var chance: float = chance_base + chance_per_level * get_level()
	var trigger_is_called: bool = Utils.rand_chance(chance)

	return trigger_is_called


func _get_properties() -> Dictionary:
	return {}


func _get_specials_modifier() -> Modifier:
	return null


func _on_attack(_event: Event):
	pass


func _on_damage(_event: Event):
	pass


func _modify_property(modification_type: int, modification_value: float):
	var can_modify_stat: bool = _modification_type_to_stat_map.has(modification_type)

	if can_modify_stat:
		var stat: int = _modification_type_to_stat_map[modification_type]
		var current_value: float = _stat_map[stat]
		var new_value: float = current_value + modification_value
		_stat_map[stat] = new_value


func _get_crit_count() -> int:
	var crit_count: int = 0

	var mod_multicrit_count: int = int(_stat_map[Stat.MOD_MULTICRIT_COUNT])
	var multicrit_count: int = int(max(0, MULTICRIT_COUNT_DEFAULT + mod_multicrit_count))

	for i in range(multicrit_count):
		var mod_attack_crit_chance: float = _stat_map[Stat.MOD_ATTACK_CRIT_CHANCE]
		var crit_chance: float = CRIT_CHANCE_DEFAULT + mod_attack_crit_chance
		var is_critical: bool = Utils.rand_chance(crit_chance)

		if is_critical:
			crit_count += 1
		else:
			break

	return crit_count


func _get_damage_mod_from_crit() -> float:
	var mod_attack_crit_damage: float =  _stat_map[Stat.MOD_ATTACK_CRIT_DAMAGE]
	var crit_mod: float = CRIT_DAMAGE_DEFAULT + mod_attack_crit_damage

	return crit_mod


func _get_damage_mod_for_mob_type(mob: Mob) -> float:
	var mob_type: int = mob.get_type()
	var stat_for_type: int = _mob_type_to_stat_map[mob_type]
	var stat_value: float = _stat_map[stat_for_type]

	return stat_value


func _get_damage_mod_for_mob_size(mob: Mob) -> float:
	var mob_size: int = mob.get_size()
	var stat_for_size: int = _mob_size_to_stat_map[mob_size]
	var stat_value: float = _stat_map[stat_for_size]

	return stat_value


func _get_damage_to_mob(mob: Mob, damage_base: float) -> float:
	var damage: float = damage_base
	
	var damage_mod_list: Array = [
		_get_damage_mod_for_mob_size(mob),
		_get_damage_mod_for_mob_type(mob),
	]

# 	NOTE: crit count can go above 1 because of the multicrit
# 	stat
	var crit_count: int = _get_crit_count()
	var crit_mod: float = _get_damage_mod_from_crit()

	for i in range(crit_count):
		damage_mod_list.append(crit_mod)

#	NOTE: clamp at 0.0 to prevent damage from turning
#	negative
	for damage_mod in damage_mod_list:
		damage *= max(0.0, (1.0 + damage_mod))

	return damage
