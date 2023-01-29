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

var attack_type: String
var ingame_name: String
var author: String
var rarity: String
var element: String
var trigger_parameters: Dictionary
var splash: Dictionary
var cost: float
var description: String
var target_mob: Mob = null
var aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var stat_map: Dictionary = {
	Stat.ATTACK_RANGE: 0.0,
	Stat.ATTACK_CD: 0.0,
	Stat.ATTACK_DAMAGE_MIN: 0,
	Stat.ATTACK_DAMAGE_MAX: 0,
	Stat.CRIT_CHANCE: 0.0,
	Stat.CRIT_BONUS: 1.0,
	Stat.MISS_CHANCE: 0.0,
}

onready var game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
onready var targeting_area: Area2D = $TargetingArea


func _ready():
	add_child(aoe_scene.instance(), true)
	
	var properties: Dictionary = _get_properties()
	attack_type = properties["attack_type"]
	ingame_name = properties["name"]
	author = properties["author"]
	rarity = properties["rarity"]
	element = properties["element"]
	splash = properties["splash"]
	cost = properties["cost"]
	description = properties["description"]
	trigger_parameters = properties["trigger_parameters"]
	
	var specials_modifier: Modifier = _get_specials_modifier()

	if specials_modifier != null:
		add_modifier(specials_modifier)

	var base_stats: Dictionary = properties["base_stats"]
	
# 	NOTE: iterate over keys in properties not stat_map[
# 	because map in properties may not define all keys
	for stat in base_stats.keys():
		stat_map[stat] = base_stats[stat]

	load_stats()

	$AreaOfEffect.hide()

	attack_cooldown_timer.connect("timeout", self, "_on_AttackCooldownTimer_timeout")
	attack_cooldown_timer.one_shot = true

	targeting_area.connect("body_entered", self, "_on_TargetingArea_body_entered")
	targeting_area.connect("body_exited", self, "_on_TargetingArea_body_exited")


func _on_AttackCooldownTimer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_attack()


func _on_TargetingArea_body_entered(body):
	if have_target():
		return
		
	if body is Mob:
#		New target acquired
		target_mob = body
		try_to_attack()


func _on_TargetingArea_body_exited(body):
	if body == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_attack()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var body_list: Array = targeting_area.get_overlapping_bodies()
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


func try_to_attack():
	if building_in_progress:
		return

	if !have_target():
		return
	
	var attack_on_cooldown: bool = attack_cooldown_timer.time_left > 0
	
	if attack_on_cooldown:
		return

	var event: Event = Event.new()
	event.target = target_mob

	var on_attack_is_called: bool = get_trigger_is_called(TriggerParameter.ON_ATTACK_CHANCE, TriggerParameter.ON_ATTACK_CHANCE_LEVEL_ADD)

	if on_attack_is_called:
		_on_attack(event)

	if event.can_attack:
		var projectile = projectile_scene.instance()
		projectile.init(target_mob, global_position)
		projectile.connect("reached_mob", self, "on_projectile_reached_mob")
		game_scene.call_deferred("add_child", projectile)

	attack_cooldown_timer.start()


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)


func build_init():
	.build_init()
	$AreaOfEffect.show()


func _select():
	._select()
	print_debug("Tower %s has been selected." % id)


func _unselect():
	._unselect()
	print_debug("Tower %s has been unselected." % id)


func upgrade() -> PackedScene:
	var next_tier_tower = TowerManager.get_tower(next_tier_id)
	emit_signal("upgraded")
	return next_tier_tower


func on_projectile_reached_mob(mob: Mob):
	var is_miss: bool = get_is_miss()

	if is_miss:
		return

	var damage_base: float = get_rand_damage_base()

#	NOTE: apply event's damage, so that any changes done by
#	scripts in _on_damage() apply
	apply_damage_to_mob(mob, damage_base)
	do_splash_attack(mob, damage_base)


func do_splash_attack(splash_target: Mob, damage_base: float):
	if splash.empty():
		return

	var splash_pos: Vector2 = splash_target.position
	var splash_range_list: Array = splash.keys()
	
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
				var splash_damage_ratio: float = splash[splash_range]
				var splash_damage: float = damage_base * splash_damage_ratio
				apply_damage_to_mob(mob, splash_damage)

				break


# TODO: need to handle application of all bonuses, for both
# normal damage and splash attack and handle bonuses
# incoming from spell scripts
func apply_damage_to_mob(mob: Mob, damage_base: float):
	var damage_mod: float = 0.0
	
	var is_critical: bool = get_is_critical()
	if is_critical:
		damage_mod += stat_map[Stat.CRIT_BONUS]

	var damage_modded: float = damage_base + damage_mod

	var event: Event = Event.new()
	event.damage = damage_modded
	event.target = mob

	var on_damage_is_called: bool = get_trigger_is_called(TriggerParameter.ON_DAMAGE_CHANCE, TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD)

	if on_damage_is_called:
		_on_damage(event)

#	NOTE: apply event's damage, so that any changes done by
#	scripts in _on_damage() apply
	mob.apply_damage(event.damage)


func get_is_critical() -> bool:
	var crit_chance: float = stat_map[Stat.CRIT_CHANCE]
	var is_critical: bool = Utils.rand_chance(crit_chance)

	return is_critical


func get_is_miss() -> bool:
	var miss_chance: float = stat_map[Stat.MISS_CHANCE]
	var out: bool = Utils.rand_chance(miss_chance)

	return out


func _change_level(new_level: int):
	._change_level(new_level)

# 	NOTE: stats could've change due to level up so re-load them
	load_stats()


func load_stats():
	var cast_range: float = stat_map[Stat.ATTACK_RANGE]
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)
	$AreaOfEffect.set_radius(cast_range)

	var attack_cd: float = stat_map[Stat.ATTACK_CD]
	attack_cooldown_timer.wait_time = attack_cd


# NOTE: returns random damage within range without any mods applied
func get_rand_damage_base() -> float:
	var damage_min: int = stat_map[Stat.ATTACK_DAMAGE_MIN]
	var damage_max: int = stat_map[Stat.ATTACK_DAMAGE_MAX]
	var damage: float = float(Utils.randi_range(damage_min, damage_max))

	return damage


func get_trigger_is_called(trigger_chance: int, trigger_chance_level_add: int) -> bool:
	var chance_base: float = trigger_parameters[trigger_chance]
	var chance_per_level: float = trigger_parameters[trigger_chance_level_add]
	var chance: float = chance_base + chance_per_level * level
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
			var current_crit_chance: float = stat_map[Stat.CRIT_CHANCE]
			var new_crit_chance: float = min(1.0, current_crit_chance + value)

			stat_map[Stat.CRIT_CHANCE] = new_crit_chance
