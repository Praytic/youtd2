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
	CRIT_CHANCE,
	CRIT_BONUS,
	MISS_CHANCE,
}

enum TriggerParameter {
	ON_DAMAGE_CHANCE,
	ON_DAMAGE_CHANCE_LEVEL_ADD,
	ON_ATTACK_CHANCE,
	ON_ATTACK_CHANCE_LEVEL_ADD,
}

export(int) var id
export(int) var next_tier_id

var _attack_type: String
var _ingame_name: String
var _author: String
var _rarity: String
var _element: String
var _trigger_parameters: Dictionary
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
	Stat.CRIT_CHANCE: 0.0,
	Stat.CRIT_BONUS: 1.0,
	Stat.MISS_CHANCE: 0.0,
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
	_trigger_parameters = properties["trigger_parameters"]
	
	var specials_modifier: Modifier = _get_specials_modifier()

	if specials_modifier != null:
		add_modifier(specials_modifier)

	var base_stats: Dictionary = properties["base_stats"]
	
# 	NOTE: iterate over keys in properties not stat_map[
# 	because map in properties may not define all keys
	for stat in base_stats.keys():
		_stat_map[stat] = base_stats[stat]

	_load_stats()

	$AreaOfEffect.hide()

	_attack_cooldown_timer.connect("timeout", self, "_on_AttackCooldownTimer_timeout")
	_attack_cooldown_timer.one_shot = true

	_targeting_area.connect("body_entered", self, "_on_TargetingArea_body_entered")
	_targeting_area.connect("body_exited", self, "_on_TargetingArea_body_exited")


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
	var damage_mod: float = 0.0
	
	var is_critical: bool = _get_stat_chance(Stat.CRIT_CHANCE)
	if is_critical:
		damage_mod += _stat_map[Stat.CRIT_BONUS]

	var damage_modded: float = damage_base + damage_mod

	var event: Event = Event.new()
	event.damage = damage_modded
	event.target = mob

	var on_damage_is_called: bool = _get_trigger_is_called(TriggerParameter.ON_DAMAGE_CHANCE, TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD)

	if on_damage_is_called:
		_on_damage(event)

#	NOTE: apply event's damage, so that any changes done by
#	scripts in _on_damage() apply
	mob.apply_damage(event.damage)


func _get_stat_chance(stat: int) -> bool:
	var unbounded_chance: float = _stat_map[stat]
	var chance: float = _get_bounded_chance(unbounded_chance)
	var is_critical: bool = Utils.rand_chance(chance)

	return is_critical


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


func _modify_property(modification_type: int, value: float):
	match modification_type:
		Modification.Type.MOD_ATTACK_CRIT_CHANCE:
			var current_crit_chance: float = _stat_map[Stat.CRIT_CHANCE]
			var new_crit_chance: float = current_crit_chance + value

			_stat_map[Stat.CRIT_CHANCE] = new_crit_chance


func _get_bounded_chance(chance: float) -> float:
	var bounded_chance: float = min(1.0, max(0.0, chance))

	return bounded_chance
