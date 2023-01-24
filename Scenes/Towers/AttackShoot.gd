extends Node2D


onready var game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var attack_timer: Timer = $AttackTimer


var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var target_mob: Mob = null
var attack_cd: float
var aura_list: Array = []


func _ready():
	pass # Replace with function body.


func init(properties):
	attack_cd = properties["attack_cd"]

	var attack_range = properties["attack_range"]
	Utils.circle_shape_set_radius($AttackArea/CollisionShape2D, attack_range)

	aura_list = properties["aura_list"]


func _on_AttackTimer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_shoot()


func _on_AttackArea_body_entered(body):
	if have_target():
		return
		
	if body is Mob:
#		New target acquired
		target_mob = body
		try_to_shoot()


func _on_AttackArea_body_exited(body):
	if body == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_shoot()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var body_list: Array = $AttackArea.get_overlapping_bodies()
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


func try_to_shoot():
	if !have_target():
		return

	var shoot_on_cd = attack_timer.time_left > 0
	
	if shoot_on_cd:
		return
	
	var projectile = projectile_scene.instance()
	projectile.target_mob = target_mob
	projectile.position = global_position
	projectile.aura_list = aura_list
	
	game_scene.call_deferred("add_child", projectile)
	
	attack_timer.start(attack_cd)


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)

