class_name Projectile
extends KinematicBody2D


# Projectile moves towards the target and disappears when it
# reaches the target.


signal target_hit(projectile)
signal interpolation_finished(projectile)

var _target: Unit = null
var _last_known_position: Vector2 = Vector2.ZERO
var _speed: float = 100
const CONTACT_DISTANCE: int = 30
var _explosion_scene: PackedScene = preload("res://Scenes/Explosion.tscn")
var _game_scene: Node = null

var user_int: int = 0
var user_int2: int = 0
var user_int3: int = 0
var user_real: float = 0.0
var user_real2: float = 0.0
var user_real3: float = 0.0


# TODO: use model. Currently using placeholder sprite.
# TODO: implement lifetime
func create(_model: String, _lifetime: float, speed: float):
	_speed = speed


func create_interpolate(_model: String, speed: float):
	_speed = speed


# TODO: targeted - If true, projectile has "homing" behavior
# and follows unit as it moves. If false, projectile flies
# to position the unit had when create() was called.
#
# TODO: ignore_target_z - ignore target height value,
# projectile flies straight without changing it's height to
# match target height. Probably relevant to air units?
# 
# TODO: expire_when_reached - if true, overrides the
# "lifetime" property and expires when reaching target, no
# matter if lifetime is shorter or longer than the time it
# takes to reach the target
func create_from_unit_to_unit(caster: Unit, _damage_ratio: float, _crit_ratio: float, from: Unit, target: Unit, _targeted: bool, _ignore_target_z: bool, _expire_when_reached: bool):
	_target = target
	position = from.get_visual_position()
	_game_scene = caster.get_tree().get_root().get_node("GameScene")

	_game_scene.call_deferred("add_child", self)
	_target.connect("death", self, "_on_target_death")


# TODO: implement actual interpolation, for now calling
# normal create()
func create_linear_interpolation_from_unit_to_unit(caster: Unit, damage_ratio: float, crit_ratio: float, from: Unit, target: Unit, _z_arc: float, targeted: bool):
	create_from_unit_to_unit(caster, damage_ratio, crit_ratio, from, target, targeted, false, true)


func _process(delta):
#	Move towards mob
	var target_pos = _get_target_position()
	var pos_diff = target_pos - position
	var move_vector = _speed * pos_diff.normalized() * delta
	position += move_vector

	var reached_mob = pos_diff.length() < CONTACT_DISTANCE

	if reached_mob:
		if _target != null:
			emit_signal("target_hit", self)

#			TODO: emit interpolation_finished() signal when
#			interpolation finishes.
			emit_signal("interpolation_finished", self)

		var explosion = _explosion_scene.instance()
		explosion.position = global_position
		_game_scene.call_deferred("add_child", explosion)

		queue_free()


func get_target() -> Unit:
	return _target


# NOTE: unlike buff and unit events, there's no weird stuff
# like trigger chances, so projectile events can be
# implemented as simple signals. These set_event() f-ns are
# still needed to match original API.

func set_event_on_target_hit(handler_object: Object, handler_function: String):
	connect("target_hit", handler_object, handler_function)


func set_event_on_interpolation_finished(handler_object: Object, handler_function: String):
	connect("interpolation_finished", handler_object, handler_function)


func _get_target_position() -> Vector2:
	if _target != null:
		var target_pos: Vector2 = _target.get_visual_position()

		return target_pos
	else:
		return _last_known_position


func _on_target_death(_event: Event):
	_last_known_position = _get_target_position()
	_target = null
