class_name Buff
extends Node


# Buff stores buff parameters and applies them to target
# while it is active. Subclasses should be defined in
# separate scripts because script path is used to get the
# unique identifier for buff. If you want to define a
# subclass as inner class, you must override get_id() and
# return something unique.

# TODO: what is friendly used for? It's not used as sign
# multiplier on value (confirmed by original tower scripts).
# Maybe used for stacking behavior?

signal expired()

enum ModifierLevelType {
	TOWER,
	BUFF,
}

var _tower: Tower
var _modifier: Modifier setget set_modifier, get_modifier
var _timer: Timer
var _level: int
var _modifier_level_type: int = ModifierLevelType.TOWER
var _friendly: bool


func _init(tower: Tower, time: float, time_level_add: float, level: int, friendly: bool):
	_tower = tower
	_level = level
	_friendly = friendly

#	NOTE: set a default empty modifier for convenience so that
# 	buffs that don't use modifiers don't need to set it
	var default_modifier: Modifier = Modifier.new()
	set_modifier(default_modifier)

	_timer = Timer.new()
	add_child(_timer)
# 	Set autostart so timer starts when add_child() is called
# 	on buff
	_timer.autostart = true
	var total_time: float = time + time_level_add * _level
	_timer.wait_time = total_time
	_timer.connect("timeout", self, "_on_timer_timeout")


func set_modifier_level_type(level_type: int):
	_modifier_level_type = level_type
	
	if _modifier != null:
		_modifier.level = _get_modifier_level()


func set_modifier(modifier: Modifier):
	_modifier = modifier
	_modifier.level = _get_modifier_level()


func get_modifier() -> Modifier:
	return _modifier


func get_level() -> int:
	return _level


func get_id() -> String:
	var script: Reference = get_script()
	var id: String = script.get_path()

	return id


func get_target() -> Unit:
	return get_parent() as Unit


func stop():
	_on_timer_timeout()


func _get_modifier_level() -> int:
	match _modifier_level_type:
		ModifierLevelType.TOWER: return _tower.get_level()
		ModifierLevelType.BUFF: return get_level()
	return 0


func _on_timer_timeout():
	emit_signal("expired")
