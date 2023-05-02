extends Node


# Stores the wave level of the most recent wave that has
# been spawned. Wave level changes when a wave is cleared.


signal changed()


var _last_cleared_wave_level: int = 0


@onready var _wave_spawner: WaveSpawner = get_tree().get_root().get_node("GameScene/Map/WaveSpawner")


func _ready():
	_wave_spawner.wave_ended.connect(_on_wave_ended)


# Current wave level is the level of the current wave if the wave is in progress or the level of the next wave if a in
# progress or the level of the next wave if 
func get_current():
	var current_level: int = _last_cleared_wave_level + 1

	return current_level


func _on_wave_ended(wave: Wave):
	_last_cleared_wave_level = wave.get_wave_number()
	changed.emit()
