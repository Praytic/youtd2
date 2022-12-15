extends RotatingTower


var target_mob: Mob = null
var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")

# TODO: load shoot_cd from somewhere
export var shoot_cd = 1.0
var shoot_timer: Timer


func _ready():
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	var _connect_error = shoot_timer.connect("timeout", self, "_on_shoot_timer_timeout")
	add_child(shoot_timer)


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)


func _on_Area2D_body_entered(body):
	if have_target():
		return
		
	var owner = body.get_owner()

	if owner is Mob:
#		New target acquired
		target_mob = owner
		try_to_shoot()


func _on_Area2D_body_exited(body):
	var owner = body.get_owner()

	if owner == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_shoot()


func _on_shoot_timer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_shoot()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var body_list: Array = $Area2D.get_overlapping_bodies()
	var closest_mob: Mob = null
	var distance_min: float = 1000000.0
	
	for body in body_list:
		var owner: Node = body.get_owner()
	
		if owner is Mob:
			var mob: Mob = owner
			var distance: float = (mob.position - position).length()
			
			if distance < distance_min:
				closest_mob = mob
				distance_min = distance
	
	return closest_mob


func try_to_shoot():
	if !have_target():
		return

	if building_in_progress:
		return
	
	var shoot_on_cd = shoot_timer.time_left > 0
	
	if shoot_on_cd:
		return
	
	var projectile = projectile_scene.instance()
	projectile.target_mob = target_mob
	
	var tower_center = position + $Base.texture.get_size() / 2
	projectile.position = tower_center
	
#		TODO: move this to utils as get_game_scene()
	var game_scene = get_tree().get_root().get_node("GameScene")
	game_scene.add_child(projectile)
	
	shoot_timer.start(shoot_cd)
	
