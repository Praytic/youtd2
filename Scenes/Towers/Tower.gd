class_name Tower
extends Building


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
var trigger_parameters: Dictionary
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
	Properties.TowerStat.ATTACK_DAMAGE_MIN: 0,
	Properties.TowerStat.ATTACK_DAMAGE_MAX: 0,
	Properties.TowerStat.CRIT_CHANCE: 0.0,
	Properties.TowerStat.CRIT_BONUS: 1.0,
	Properties.TowerStat.MISS_CHANCE: 0.0,
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
	effects = properties["effects"]
	trigger_parameters = properties["trigger_parameters"]

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

	var event: Event = Event.new()
	event.target = target_mob

	var on_attack_is_called: bool = get_trigger_is_called(Properties.TriggerParameter.ON_ATTACK_CHANCE, Properties.TriggerParameter.ON_ATTACK_CHANCE_LEVEL_ADD)

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
		damage_mod += get_tower_stat(Properties.TowerStat.CRIT_BONUS)

	var damage_modded: float = damage_base + damage_mod

	var event: Event = Event.new()
	event.damage = damage_modded
	event.target = mob

	var on_damage_is_called: bool = get_trigger_is_called(Properties.TriggerParameter.ON_DAMAGE_CHANCE, Properties.TriggerParameter.ON_DAMAGE_CHANCE_LEVEL_ADD)

	if on_damage_is_called:
		_on_damage(event)

#	NOTE: apply event's damage, so that any changes done by
#	scripts in _on_damage() apply
	mob.apply_damage(event.damage)


func get_tower_stat(tower_stat: int) -> float:
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


func get_is_critical() -> bool:
	var crit_chance: float = get_tower_stat(Properties.TowerStat.CRIT_CHANCE)
	var is_critical: bool = Utils.rand_chance(crit_chance)

	return is_critical


func get_is_miss() -> bool:
	var miss_chance: float = get_tower_stat(Properties.TowerStat.MISS_CHANCE)
	var out: bool = Utils.rand_chance(miss_chance)

	return out


func level_up():
#	Stats could've changed after level up so re-load stats
	load_stats()


func load_stats():
	var cast_range: float = get_tower_stat(Properties.TowerStat.ATTACK_RANGE)
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)
	$AreaOfEffect.set_radius(cast_range)

	var attack_cd: float = get_tower_stat(Properties.TowerStat.ATTACK_CD)
	attack_cooldown_timer.wait_time = attack_cd


# NOTE: returns random damage within range without any mods applied
func get_rand_damage_base() -> float:
	var damage_min: int = get_tower_stat(Properties.TowerStat.ATTACK_DAMAGE_MIN)
	var damage_max: int = get_tower_stat(Properties.TowerStat.ATTACK_DAMAGE_MAX)
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
	

func _on_attack(_event: Event):
	pass


func _on_damage(_event: Event):
	pass
