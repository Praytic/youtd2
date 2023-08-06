extends Node


# Stores the wave level of the most recent wave that has
# been spawned. Wave level changes when a wave is cleared.


signal changed()


var _current_level: int = 0


# Current level is the level of the last started wave.
# Starts at 0 and becomes 1 when the first wave starts.
func get_current():
	return _current_level


func increase():
	_current_level += 1
	changed.emit()
