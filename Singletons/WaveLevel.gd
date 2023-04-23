extends Node

signal changed()


var _wave_level: int = 1


func increment():
	_wave_level += 1
	changed.emit()


func get_current():
	return _wave_level
