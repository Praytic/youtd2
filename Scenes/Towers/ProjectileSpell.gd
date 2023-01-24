extends Node2D


onready var game_scene: Node = get_tree().get_root().get_node("GameScene")
onready var cast_timer: Timer = $CastTimer


var projectile_scene: PackedScene = preload("res://Scenes/Projectile.tscn")
var target_mob: Mob = null
var default_cast_cd: float
var cast_cd: float
var cast_cd_mod: float = 0.0
var aura_list: Array = []


func _ready():
	pass # Replace with function body.


func init(properties):
	default_cast_cd = properties[Properties.SpellParameter.CAST_CD]
	cast_cd = default_cast_cd

	var cast_range = properties[Properties.SpellParameter.CAST_RANGE]
	Utils.circle_shape_set_radius($TargetingArea/CollisionShape2D, cast_range)

	aura_list = properties[Properties.SpellParameter.AURA_LIST]


func _on_CastTimer_timeout():
	if !have_target():
		target_mob = find_new_target()
		
	try_to_shoot()


func _on_TargetingArea_body_entered(body):
	if have_target():
		return
		
	if body is Mob:
#		New target acquired
		target_mob = body
		try_to_shoot()


func _on_TargetingArea_body_exited(body):
	if body == target_mob:
#		Target has gone out of range
		target_mob = find_new_target()
		try_to_shoot()


# Find a target that is currently in range
# TODO: prioritizing closest mob here, but maybe change behavior
# based on tower properties or other game design considerations
func find_new_target() -> Mob:
	var body_list: Array = $TargetingArea.get_overlapping_bodies()
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

	var shoot_on_cd = cast_timer.time_left > 0
	
	if shoot_on_cd:
		return
	
	var projectile = projectile_scene.instance()
	projectile.target_mob = target_mob
	projectile.position = global_position
	projectile.aura_list = aura_list
	
	game_scene.call_deferred("add_child", projectile)
	
	cast_timer.start(cast_cd)


func have_target() -> bool:
#	NOTE: have to check validity because mobs can get killed by other towers
#	which free's them and makes them invalid
	return target_mob != null and is_instance_valid(target_mob)


func apply_aura(aura: Aura):
	match aura.type:
		Properties.AuraType.DECREASE_CAST_CD:
			if aura.is_expired:
				cast_cd_mod = 0.0
			else:
				cast_cd_mod = aura.get_value()

			cast_cd = default_cast_cd * (1.0 - cast_cd_mod)
		_: print_debug("unhandled aura.type in ProximitySpell.apply_aura():", aura.type)
