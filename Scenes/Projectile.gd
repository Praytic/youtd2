extends KinematicBody2D


var target_mob: Mob = null
export var speed: int = 100
export var contact_distance: int = 30


# TODO: duplicated in GunT1.gd, move somewhere to share in both places
func have_target() -> bool:
	return target_mob != null and is_instance_valid(target_mob)

func _process(delta):
	if !have_target():
		queue_free()
		return
	
#	Move towards mob
	var target_pos = target_mob.position
	var pos_diff = target_pos - position
	
	var reached_mob = pos_diff.length() < contact_distance
	
	if reached_mob:
#		TODO: read damage number from tower parameters
		target_mob.apply_damage(4)
		queue_free()
		return
	
	var move_vector = speed * pos_diff.normalized() * delta
	
	position += move_vector
	
