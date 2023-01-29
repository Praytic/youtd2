extends KinematicBody2D


# Projectile moves towards the target and disappears when it
# reaches the target.

signal reached_mob(mob)

onready var object_container = get_tree().get_root().get_node("GameScene").get_node("Map").get_node("MobYSort")

var target_mob: Mob = null
export var speed: int = 100
export var contact_distance: int = 30


func init(target_mob_arg: Mob, tower_position: Vector2):
	target_mob = target_mob_arg
	position = tower_position


func _have_target() -> bool:
	return target_mob != null and is_instance_valid(target_mob)


func _process(delta):
	if !_have_target():
		queue_free()
		return
	
#	Move towards mob
	var target_pos = target_mob.position
	var pos_diff = target_pos - position
	var move_vector = speed * pos_diff.normalized() * delta
	position += move_vector

	var reached_mob = pos_diff.length() < contact_distance

	if reached_mob:
		emit_signal("reached_mob", target_mob)
		queue_free()
