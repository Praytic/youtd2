extends Node

# Buff represents an applied BuffType with a duration timer.
# It applies modifications when it starts and undoes
# modifications when it expires.

class_name Buff


signal expired(buff)

var tower: Tower
var target: Mob
var modifier: Modifier
var value_modifier: float
var duration_timer: Timer


func _init(tower_arg: Tower, target_arg: Mob, value_modifier_arg: float, duration: float, modifier_arg: Modifier):
	tower = tower_arg
	target = target_arg
	value_modifier = value_modifier_arg
	modifier = modifier_arg

	duration_timer = Timer.new()
	add_child(duration_timer)
	duration_timer.one_shot = true
	duration_timer.autostart = true
	duration_timer.wait_time = duration
	duration_timer.connect("timeout", self, "on_duration_timer_timeout")

	if modifier != null:
		modifier.apply(target, value_modifier)


func on_duration_timer_timeout():
#	NOTE: target can become invalid if it dies before the
#	buff expires.
	if modifier != null && is_instance_valid(target):
		modifier.undo_apply(target, value_modifier)

	emit_signal("expired", self)

	queue_free()


func stop():
	on_duration_timer_timeout()
