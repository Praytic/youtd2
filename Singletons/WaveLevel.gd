extends Node


# Stores the wave level of the most recent wave that has
# been spawned. Wave level changes when a new wave starts
# spawning.


signal changed()


# NOTE: on startup, no waves have been spawned yet so
# current wave level is 0 and corresponds to no wave.
var _wave_level: int = 0


func increment():
	_wave_level += 1
	changed.emit()


func get_current():
	return _wave_level
