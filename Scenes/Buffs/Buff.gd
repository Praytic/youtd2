extends Node


# Buff stores buff parameters and applies them to target
# while it is active. Subclasses should be defined in
# separate scripts because script path is used to get the
# unique identifier for buff. If you want to define a
# subclass as inner class, you must override get_id() and
# return something unique.

class_name Buff


signal expired()

var tower: Tower
var target: Unit
var modifier: Modifier
var value_modifier: float
var duration_timer: Timer
var power_level: int
var duration: float


func _init(tower_arg: Tower, duration_arg: float, value_modifier_arg: float, power_level_arg: int):
	tower = tower_arg
	value_modifier = value_modifier_arg
	duration = duration_arg
	power_level = power_level_arg

	duration_timer = Timer.new()
	add_child(duration_timer)
	duration_timer.connect("timeout", self, "on_duration_timer_timeout")


func set_modifier(modifier_arg: Modifier):
	modifier = modifier_arg


func get_id() -> String:
	var script: Reference = get_script()
	var id: String = script.get_path()

	return id


func stop():
	on_duration_timer_timeout()


func on_apply_success(target_arg: Unit):
	target = target_arg

	if modifier != null:
		modifier.apply(target, value_modifier)

	duration_timer.start(duration)


func on_duration_timer_timeout():
#	NOTE: target can become invalid if it dies before the
#	buff expires.
	if modifier != null && is_instance_valid(target):
		modifier.remove(target, value_modifier)

	emit_signal("expired")

	queue_free()
