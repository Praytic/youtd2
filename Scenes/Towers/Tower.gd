extends Building


class_name Tower


signal upgraded


enum AttackStyle {
	Shoot,
	Aoe,
	None,
}


export(int) var id
export(int) var next_tier_id

var attack_type: String
var attack_range: float setget set_attack_range
var attack_cd: float
var attack_style_string: String
var ingame_name: String
var author: String
var rarity: String
var element: String
var damage_l: float
var damage_r: float
var cost: float
var description: String


var target_mob: Mob = null
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
var shoot_timer: Timer
var aoe_timer: Timer
var attack_style = AttackStyle.None
var aoe_scene: PackedScene = preload("res://Scenes/Towers/AreaOfEffect.tscn")


func _ready():
	add_child(aoe_scene.instance(), true)
	shoot_timer = Timer.new()
	aoe_timer = Timer.new()
	
	var properties = TowerManager.tower_props[id]
	attack_type = properties["attack_type"]
	set_attack_range(properties["attack_range"])
	attack_cd = properties["attack_cd"]
	attack_style_string = properties["attack_style"]
	ingame_name = properties["name"]
	author = properties["author"]
	rarity = properties["rarity"]
	element = properties["element"]
	damage_l = properties["damage_l"]
	damage_r = properties["damage_r"]
	cost = properties["cost"]
	description = properties["description"]

	shoot_timer.one_shot = true
	var _connect_error = shoot_timer.connect("timeout", self, "_on_shoot_timer_timeout")
	add_child(shoot_timer)

	aoe_timer.one_shot = false
	var _connect_error2 = aoe_timer.connect("timeout", self, "_on_aoe_timer_timeout")
	add_child(aoe_timer)
	aoe_timer.start(attack_cd)

	attack_style = attack_style_from_string(attack_style_string)
	
	$AreaOfEffect.hide()


func attack_style_from_string(string: String):
	match string:
		"shoot": return AttackStyle.Shoot
		"aoe": return AttackStyle.Aoe
		_: return AttackStyle.None


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)


func _on_shoot_timer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_shoot()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var body_list: Array = $AreaOfEffect/CollisionArea.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0
	
	for body in body_list:
		var owner: Node = body.get_owner()
	
		if owner is Mob:
			var mob: Mob = owner
			var distance: float = (mob.position - self.position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func try_to_shoot():
	if attack_style != AttackStyle.Shoot:
		return

	if !have_target():
		return

	if self.building_in_progress:
		return
	
	var shoot_on_cd = shoot_timer.time_left > 0
	
	if shoot_on_cd:
		return
	
	var projectile = projectile_scene.instance()
	projectile.target_mob = target_mob
	
	projectile.position = self.position
	
#		TODO: move this to utils as get_game_scene()
	var game_scene = .get_tree().get_root().get_node("GameScene")
	game_scene.call_deferred("add_child", projectile)
	
	shoot_timer.start(attack_cd)
	


func _on_ShootingArea_body_entered(body):
	if have_target():
		return
		
	var owner = body.get_owner()

	if owner is Mob:
#		New target acquired
		target_mob = owner
		try_to_shoot()


func _on_ShootingArea_body_exited(body):
	var owner = body.get_owner()

	if owner == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_shoot()


func _on_aoe_timer_timeout():
	var body_list: Array = $AreaOfEffect/CollisionArea.get_overlapping_bodies()
	
	for body in body_list:
		var owner: Node = body.get_owner()
	
		if owner is Mob:
			var mob: Mob = owner
			mob.apply_damage(4)
			
			var explosion = explosion_scene.instance()
			explosion.position = mob.position
			var game_scene = .get_tree().get_root().get_node("GameScene")
			game_scene.call_deferred("add_child", explosion)


func build_init():
	.build_init()
	$AreaOfEffect.show()


func set_attack_range(radius: float):
	attack_range = radius
	$AreaOfEffect.set_radius(radius)


func _select():
	._select()
	print("Tower %s has been selected." % id)


func _unselect():
	._unselect()
	print("Tower %s has been unselected." % id)


func upgrade() -> PackedScene:
	var next_tier_tower = TowerManager.get_tower(next_tier_id)
	emit_signal("upgraded")
	return next_tier_tower
