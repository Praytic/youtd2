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
var modifier_level_type: int = ModifierLevelType.TOWER
var value_modifier: float
var timer: Timer
var power_level: int
var time: float

enum ModifierLevelType {
	TOWER,
	BUFF
}


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


func set_modifier(modifier_arg: Modifier):
	modifier = modifier_arg


func set_modifier_level_type(modifier_level_type_arg: int):
	modifier_level_type = modifier_level_type_arg


func get_id() -> String:
	var script: Reference = get_script()
	var id: String = script.get_path()

	return id


func stop():
	_on_timer_timeout()


func _on_timer_timeout():
	emit_signal("expired")


func get_modifier_level() -> int:
	match modifier_level_type:
		ModifierLevelType.TOWER: return tower.level
		ModifierLevelType.BUFF: return power_level

	return 1
