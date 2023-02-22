extends KinematicBody2D


# Projectile moves towards the target and disappears when it
# reaches the target.

signal reached_mob(mob)

var _target_mob: Mob = null
const SPEED: int = 1000
const CONTACT_DISTANCE: int = 30
var _explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")


func init(target_mob: Mob, tower_position: Vector2):
	_target_mob = target_mob
	position = tower_position


func _have_target() -> bool:
	return _target_mob != null and is_instance_valid(_target_mob)


func _process(delta):
	if !_have_target():
		queue_free()
		return
	
#	Move towards mob
	var target_pos = _target_mob.get_visual_position()
	var pos_diff = target_pos - position
	var move_vector = SPEED * pos_diff.normalized() * delta
	position += move_vector

	var reached_mob = pos_diff.length() < CONTACT_DISTANCE

	if reached_mob:
		emit_signal("reached_mob", _target_mob)

		var explosion = _explosion_scene.instance()
		explosion.position = global_position
		_game_scene.call_deferred("add_child", explosion)

		queue_free()
