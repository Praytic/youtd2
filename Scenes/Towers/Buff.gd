extends Node

# Buff does stuff

class_name Buff


var duration_default: float


func _init(duration_default_arg: float):
	duration_default = duration_default_arg


func _ready():
	pass


func apply(tower: Tower, target: Mob, value_modifier: float):
	apply_custom_timed(tower, target, value_modifier, duration_default)


func apply_custom_timed(tower: Tower, target: Mob, value_modifier: float, duration: float):
# 	TODO: do stuff that should happen when buff is applied
# 	here. For example if buff has modifier MOD_ARMOR, apply
# 	it here.
	var duration_timer: Timer = Timer.new()
	add_child(duration_timer)
	duration_timer.connect("timeout", self, "on_duration_timer_timeout", [tower, target, value_modifier, duration, duration_timer])
	duration_timer.start(duration)


func on_duration_timer_timeout(tower: Tower, target: Mob, value_modifier: float, duration: float, duration_timer: Timer):
	duration_timer.queue_free()

# 	TODO: do stuff that should happen when buff is expired
# 	here. For example if buff has modifier MOD_ARMOR, undo
# 	application# 	it here.
