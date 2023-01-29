class_name Buff
extends Node


# Buff stores buff parameters and applies them to target
# while it is active. Subclasses should be defined in
# separate scripts because script path is used to get the
# unique identifier for buff. If you want to define a
# subclass as inner class, you must override get_id() and
# return something unique.


signal expired()

var tower: Tower
var target: Unit
var modifier: Modifier
var value_modifier: float
var timer: Timer
var power_level: int
var time: float


func _init(tower_arg: Tower, time_arg: float, time_level_add: float, value_modifier_arg: float, power_level_arg: int):
	tower = tower_arg
	value_modifier = value_modifier_arg
	time = time_arg + time_level_add * power_level_arg
	power_level = power_level_arg

	timer = Timer.new()
	add_child(timer)
# 	Set autostart so timer starts when add_child() is called
# 	on buff
	timer.autostart = true
	timer.connect("timeout", self, "_on_timer_timeout")


# Sets modifier which depends on tower level
func set_modifier(modifier_arg: Modifier):
	modifier = modifier_arg
	modifier.level = tower.level


# Sets modifier which depends on buff level
func set_buff_modifier(modifier_arg: Modifier):
	modifier = modifier_arg
	modifier.level = power_level


func get_id() -> String:
	var script: Reference = get_script()
	var id: String = script.get_path()

	return id


func stop():
	_on_timer_timeout()


func _on_timer_timeout():
	emit_signal("expired")
