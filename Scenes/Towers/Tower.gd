extends Building

class_name Tower

# Tower attacks by periodically firing projectiles at mobs
# that are in range.

signal upgraded

export(int) var id
export(int) var next_tier_id

var attack_type: String
var ingame_name: String
var author: String
var rarity: String
var element: String
var splash: Dictionary
var cost: float
var description: String
var effects: Array
var target_mob: Mob = null
var level: int = 1
var aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var stat_map: Dictionary = {
	Properties.TowerStat.ATTACK_RANGE: 0.0,
	Properties.TowerStat.ATTACK_CD: 0.0,
	Properties.TowerStat.ATTACK_DAMAGE: [0, 0],
	Properties.TowerStat.CRIT_CHANCE: 0.0,
	Properties.TowerStat.CRIT_BONUS: 1.0,
}

onready var game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var attack_cooldown_timer: Timer = $AttackCooldownTimer
onready var targeting_area: Area2D = $TargetingArea


func _ready():
	add_child(aoe_scene.instance(), true)
	
	var properties = TowerManager.tower_props[id]
	attack_type = properties["attack_type"]
	ingame_name = properties["name"]
	author = properties["author"]
	rarity = properties["rarity"]
	element = properties["element"]
	splash = properties["splash"]
	cost = properties["cost"]
	description = properties["description"]
	effects = properties["effects"]

	var base_stats: Dictionary = properties["base_stats"]
	
# 	NOTE: iterate over keys in properties not stat_map
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
	print("on_projectile_reached_mob")
	var damage: Array = get_tower_stat(Properties.TowerStat.ATTACK_DAMAGE)
	apply_damage_to_mob(mob, damage)
	do_splash_attack(mob)


func do_splash_attack(mob: Mob):
	if splash.empty():
		return

	var splash_pos: Vector2 = target_mob.position
	var splash_range_list: Array = splash.keys()
	
#	Process splash ranges from closest to furthers,
#	so that strongest damage is applied
	splash_range_list.sort()

	var splash_range_max: float = splash_range_list.back()
	var mob_list: Array = Utils.get_mob_list_in_range(splash_pos, splash_range_max)

	for mob in mob_list:
		if mob == target_mob:
			continue
		
		var distance: float = splash_pos.distance_to(mob.position)

		for splash_range in splash_range_list:
			var mob_is_in_range: bool = distance < splash_range
			var damage: Array = get_tower_stat(Properties.TowerStat.ATTACK_DAMAGE)
			var damage_mod: float = splash[splash_range]
			var splash_damage: Array = multiply_damage_range_by_mod(damage, damage_mod)
			apply_damage_to_mob(mob, splash_damage)

			break


# TODO: need to handle application of all bonuses, for both
# normal damage and splash attack and handle bonuses
# incoming from spell scripts
func apply_damage_to_mob(mob: Mob, damage: Array):
	var damage_mod: float = 0.0
	
	var is_critical: bool = get_is_critical()
	if is_critical:
		damage_mod += get_tower_stat(Properties.TowerStat.CRIT_BONUS)

	var modded_damage_range: Array = multiply_damage_range_by_mod(damage, damage_mod)
	var final_damage_value: int = Utils.randi_range(modded_damage_range[0], modded_damage_range[1])

	mob.apply_damage(final_damage_value)


func get_tower_stat_range(tower_stat: int) -> Array:
	var default_value: Array = stat_map[tower_stat]
	var effect_mod: float = get_effect_mod_for_stat(tower_stat)

	var modded_value = default_value

	for i in range(modded_value.size()):
		modded_value[i] += effect_mod

	return modded_value


func get_tower_stat_float(tower_stat: int) -> float:
	var default_value: float = stat_map[tower_stat]
	var effect_mod: float = get_effect_mod_for_stat(tower_stat)
	var modded_value = default_value + effect_mod

	return modded_value


func get_effect_mod_for_stat(tower_stat: int) -> float:
	var effect_mod: float = 0.0

	for effect in effects:
		var effect_is_mod_tower_stat: bool = effect[Properties.EffectParameter.TYPE] == Properties.EffectType.MOD_TOWER_STAT
		var effect_affects_stat: bool = effect[Properties.EffectParameter.AFFECTED_TOWER_STAT] == tower_stat
		var effect_applies: bool = effect_is_mod_tower_stat && effect_affects_stat
		
		if !effect_applies:
			continue

		var effect_value_base: float = effect[Properties.EffectParameter.VALUE_BASE]
		var effect_value_per_level: float = effect[Properties.EffectParameter.VALUE_PER_LEVEL]
		var effect_value: float = effect_value_base + effect_value_per_level * (level - 1)

		effect_mod += effect_value

	return effect_mod


func get_tower_stat(tower_stat: int):
	var default_value = stat_map[tower_stat]
	var modded_value = default_value

	if default_value is Array:
		return get_tower_stat_range(tower_stat)
	elif default_value is float:
		return get_tower_stat_float(tower_stat)
	else:
		return null


func get_is_critical() -> bool:
	var crit_chance: float = get_tower_stat(Properties.TowerStat.CRIT_CHANCE)
	var is_critical: bool = Utils.rand_chance(crit_chance)

	return is_critical


func multiply_damage_range_by_mod(damage_range: Array, damage_mod: float) -> Array:
	var damage_range_modded: Array = []

	for damage_base in damage_range:
		var modded_damage = damage_base * (1.0 + damage_mod)
		damage_range_modded.append(modded_damage)

	return damage_range_modded


func level_up():
#	Stats could've changed after level up so re-load stats
	load_stats()


func load_stats():
	var cast_range: float = get_tower_stat(Properties.TowerStat.ATTACK_RANGE)
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)
	$AreaOfEffect.set_radius(cast_range)

	var attack_cd: float = get_tower_stat(Properties.TowerStat.ATTACK_CD)
	attack_cooldown_timer.wait_time = attack_cd
