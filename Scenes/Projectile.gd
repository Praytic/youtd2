extends KinematicBody2D


# Projectile moves towards the target and disappears when it
# reaches the target.

signal reached_mob(mob)

var _target_mob: Mob = null
var _last_known_position: Vector2 = Vector2.ZERO
const SPEED: int = 1000
const CONTACT_DISTANCE: int = 30
var _explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
onready var _game_scene: Node = get_tree().get_root().get_node("GameScene")


func init(target_mob: Mob, tower_position: Vector2):
	_target_mob = target_mob
	position = tower_position
	_target_mob.connect("death", self, "_on_target_death")


func _process(delta):
#	Move towards mob
	var target_pos = _get_target_position()
	var pos_diff = target_pos - position
	var move_vector = SPEED * pos_diff.normalized() * delta
	position += move_vector

	var reached_mob = pos_diff.length() < CONTACT_DISTANCE

	if reached_mob:
		if _target_mob != null:
			emit_signal("reached_mob", _target_mob)

		var explosion = _explosion_scene.instance()
		explosion.position = global_position
		_game_scene.call_deferred("add_child", explosion)

		queue_free()


func _get_target_position() -> Vector2:
	if _target_mob != null:
		var target_pos: Vector2 = _target_mob.get_visual_position()

		return target_pos
	else:
		return _last_known_position


func _on_target_death(_event: Event):
	_last_known_position = _get_target_position()
	_target_mob = null
